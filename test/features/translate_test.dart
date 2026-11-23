import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:yoru/features/settings/domain/entities/app_settings.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:yoru/features/translate/data/datasources/llm_translator.dart';
import 'package:yoru/features/translate/data/device/mlkit_translation.dart';
import 'package:yoru/features/translate/data/ocr/ctc_decode.dart';
import 'package:yoru/features/translate/data/ocr/db_postprocess.dart';
import 'package:yoru/features/translate/data/ocr/onnx_patch.dart';
import 'package:yoru/features/translate/data/ocr/page_slices.dart';
import 'package:yoru/features/translate/data/ocr/text_grouping.dart';
import 'package:yoru/features/translate/domain/entities/page_translation.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';
import 'package:yoru/features/translate/presentation/widgets/translated_page.dart';

void main() {
  group('dbBoxes', () {
    /// A [w] × [h] map with [boxes] filled at [value].
    Float32List map(int w, int h, List<ui.Rect> boxes, {double value = 0.9}) {
      final m = Float32List(w * h);
      for (final b in boxes) {
        for (var y = b.top.toInt(); y < b.bottom; y++) {
          for (var x = b.left.toInt(); x < b.right; x++) {
            m[y * w + x] = value;
          }
        }
      }
      return m;
    }

    test('finds separate regions and grows them', () {
      final boxes = dbBoxes(
        map(100, 100, const [
          ui.Rect.fromLTWH(10, 10, 40, 8),
          ui.Rect.fromLTWH(10, 40, 30, 8),
        ]),
        100,
        100,
      );
      expect(boxes, hasLength(2));
      final first = boxes.firstWhere((b) => b.top < 20);
      expect(first.left, lessThan(10));
      expect(first.width, greaterThan(40));
      expect(first.height, greaterThan(8));
    });

    test('drops faint regions and specks', () {
      expect(
        dbBoxes(
          map(50, 50, const [ui.Rect.fromLTWH(5, 5, 20, 10)], value: 0.4),
          50,
          50,
        ),
        isEmpty,
      );
      expect(
        dbBoxes(map(50, 50, const [ui.Rect.fromLTWH(5, 5, 1, 1)]), 50, 50),
        isEmpty,
      );
    });
  });

  test('ctcDecode merges repeats and drops blanks', () {
    // Classes: blank, 'a', 'b', space. Two lines of three steps each.
    const dictionary = ['a', 'b'];
    const best = [1, 1, 0, /* next line */ 1, 3, 2];
    const scores = [0.8, 0.8, 0.9, 0.7, 0.7, 0.7];
    final first = ctcDecode(
      best,
      scores,
      offset: 0,
      steps: 3,
      dictionary: dictionary,
    );
    expect(first.text, 'a');
    final second = ctcDecode(
      best,
      scores,
      offset: 3,
      steps: 3,
      dictionary: dictionary,
    );
    expect(second.text, 'a b');
    expect(second.score, closeTo(0.7, 1e-9));
  });

  test('withBestClass adds the two outputs and keeps the model', () {
    // ModelProto: ir_version 10, opset 14, graph with one output 'out'.
    List<int> field(int n, List<int> b) => [n << 3 | 2, b.length, ...b];
    List<int> varint(int n, int v) => [n << 3, v];
    final model = Uint8List.fromList([
      ...varint(1, 10),
      ...field(8, [...field(1, []), ...varint(2, 14)]),
      ...field(7, [
        ...field(2, 'g'.codeUnits),
        ...field(12, field(1, 'out'.codeUnits)),
      ]),
    ]);
    final patched = withBestClass(model);
    expect(onnxOutputs(patched), ['out', bestClassOutput, bestScoreOutput]);
    expect(patched.sublist(0, 2), model.sublist(0, 2));
  });

  group('groupLines', () {
    test('lines of one balloon are one block, top to bottom', () {
      final blocks = groupLines(const [
        OcrLine(rect: ui.Rect.fromLTWH(100, 130, 120, 20), text: 'SECOND'),
        OcrLine(rect: ui.Rect.fromLTWH(95, 105, 130, 20), text: 'FIRST'),
        OcrLine(rect: ui.Rect.fromLTWH(500, 100, 100, 20), text: 'OTHER'),
      ]);
      expect(blocks.map((b) => b.text), ['FIRST SECOND', 'OTHER']);
      expect(blocks.first.rect.top, 105);
      expect(blocks.first.rect.bottom, 150);
    });

    test('vertical columns join right to left, without spaces', () {
      final blocks = groupLines(const [
        OcrLine(rect: ui.Rect.fromLTWH(100, 100, 20, 90), text: 'いう'),
        OcrLine(rect: ui.Rect.fromLTWH(125, 100, 20, 100), text: 'そう'),
      ]);
      expect(blocks.single.text, 'そういう');
    });

    test('ruby beside the columns is dropped, a caption kept apart', () {
      final blocks = groupLines(const [
        OcrLine(rect: ui.Rect.fromLTWH(200, 100, 40, 150), text: 'お前は'),
        OcrLine(rect: ui.Rect.fromLTWH(155, 100, 40, 150), text: '素晴らしい'),
        OcrLine(rect: ui.Rect.fromLTWH(242, 110, 12, 30), text: 'まえ'),
        OcrLine(rect: ui.Rect.fromLTWH(242, 150, 11, 11), text: 'す'),
        // A caption in bigger lettering right beside the balloon.
        OcrLine(rect: ui.Rect.fromLTWH(90, 100, 64, 200), text: 'この笑顔'),
      ]);
      expect(blocks.map((b) => b.text), ['お前は素晴らしい', 'この笑顔']);
    });

    test('a hyphenated word is joined back', () {
      final blocks = groupLines(const [
        OcrLine(rect: ui.Rect.fromLTWH(0, 0, 100, 20), text: 'WON-'),
        OcrLine(rect: ui.Rect.fromLTWH(0, 24, 100, 20), text: 'DERFUL'),
      ]);
      expect(blocks.single.text, 'WONDERFUL');
    });
  });

  test('sliceStarts covers the page with overlapping slices', () {
    expect(sliceStarts(1000, 1000), [0]);
    expect(sliceStarts(1100, 1000), [0]);
    final starts = sliceStarts(5000, 1000);
    expect(starts.first, 0);
    expect(starts.last + 1000, 5000);
    for (var i = 1; i < starts.length; i++) {
      expect(starts[i] - starts[i - 1], lessThan(1000), reason: 'overlap');
    }
  });

  group('parseTranslations', () {
    test('reads them by number, whatever their order', () {
      expect(parseTranslations('{"2":"Pergi!","1":"Halo"}', 2), [
        'Halo',
        'Pergi!',
      ]);
      expect(parseTranslations('{"translations":{"1":"A","2":"B"}}', 2), [
        'A',
        'B',
      ]);
    });

    test('a skipped number stays empty without shifting the rest', () {
      expect(parseTranslations('{"1":"A","3":"C"}', 3), ['A', '', 'C']);
    });

    test('still reads a plain list in order', () {
      expect(parseTranslations('```json\n["A"]\n```', 2), ['A', '']);
      expect(parseTranslations('{"translations":["A","B","C"]}', 2), [
        'A',
        'B',
      ]);
    });

    test('reads the texts out of broken JSON', () {
      expect(
        parseTranslations(
          r'{"1": "Dan di situlah," "2": "kesadaranku \"pun\" memudar."}',
          2,
        ),
        ['Dan di situlah,', 'kesadaranku "pun" memudar.'],
      );
    });

    test('no JSON throws', () {
      expect(
        () => parseTranslations('Sorry, I cannot.', 1),
        throwsFormatException,
      );
    });
  });

  test('translatePrompt carries the style, the comic and the notes', () {
    final prompt = translatePrompt(
      'Indonesian',
      comic: 'Kuro Homura',
      notes: 'pakai gue/lo',
    );
    expect(prompt, contains('aku/kamu'));
    expect(prompt, contains('never gue/lo'));
    expect(prompt, contains('"Kuro Homura"'));
    expect(prompt, contains('pakai gue/lo'));
    final plain = translatePrompt('Japanese');
    expect(plain, isNot(contains('The comic')));
    expect(plain, isNot(contains('The reader asks')));
  });

  test('notes change the cache key, the comic does not', () {
    const a = TranslatorConfig(
      baseUrl: 'u',
      apiKey: '',
      model: 'm',
      language: 'Indonesian',
    );
    const b = TranslatorConfig(
      baseUrl: 'u',
      apiKey: '',
      model: 'm',
      language: 'Indonesian',
      notes: 'pakai gue/lo',
    );
    expect(a.cacheTag, isNot(b.cacheTag));
    expect(a.forComic('X').cacheTag, a.cacheTag);
  });

  test('noThinking per server', () {
    expect(noThinking('https://api.deepseek.com/v1'), {
      'thinking': {'type': 'disabled'},
    });
    expect(noThinking('https://api.anthropic.com/v1'), isEmpty);
    expect(noThinking('https://api.openai.com/v1'), {
      'reasoning_effort': 'none',
    });
  });

  group('layoutBubble', () {
    const bounds = ui.Rect.fromLTWH(0, 0, 800, 1200);

    test('covers the lettering and stays in the image', () {
      const area = ui.Rect.fromLTWH(100, 100, 200, 300);
      final b = layoutBubble(area, 'Halo', bounds: bounds);
      expect(b.rect.width, greaterThan(area.width));
      expect(b.rect.contains(area.center), isTrue);
      expect(b.fontSize, inInclusiveRange(9, 18));
      final edge = layoutBubble(
        const ui.Rect.fromLTWH(0, 0, 200, 100),
        'Halo',
        bounds: bounds,
      );
      expect(edge.rect.left, 0);
      expect(edge.rect.top, 0);
    });

    test('a long line in a tiny box grows the bubble, not below 9', () {
      const area = ui.Rect.fromLTWH(400, 600, 30, 20);
      final b = layoutBubble(
        area,
        'Aku kagum kau bisa melakukannya tanpa rasa malu.',
        bounds: bounds,
      );
      expect(b.fontSize, 9);
      expect(b.rect.width, greaterThan(60));
      expect(b.rect.height, greaterThan(40));
      expect((b.rect.center - area.center).distance, lessThan(1));
    });
  });

  test('bubbleFontSizes follow the original letters', () {
    // Letters 2.5 % of the page wide, shown 800 px wide: 16 px.
    final sizes = bubbleFontSizes(0.025, 800);
    expect(sizes.max, closeTo(16, 1e-9));
    expect(sizes.min, closeTo(11.2, 1e-9));
    // Unknown: the page's usual size.
    expect(bubbleFontSizes(null, 800).max, bubbleMaxFontSize(800));
    // Huge letters are capped.
    expect(bubbleFontSizes(0.2, 800).max, 28);
  });

  test('a block knows the size of its letters and keeps it stored', () {
    final block = groupLines(const [
      OcrLine(rect: ui.Rect.fromLTWH(0, 0, 100, 20), text: 'ONE'),
      OcrLine(rect: ui.Rect.fromLTWH(0, 24, 100, 22), text: 'TWO'),
    ]).single;
    expect(block.letterSize, 22);
    const stored = TextBlock(
      left: 0,
      top: 0,
      right: 1,
      bottom: 1,
      text: 'x',
      letterSize: 0.03,
    );
    expect(TextBlock.fromJson(stored.toJson()).letterSize, 0.03);
  });

  test('bubbleMaxFontSize follows the page width', () {
    expect(bubbleMaxFontSize(400), closeTo(10, 1e-9));
    expect(bubbleMaxFontSize(200), 9);
    expect(bubbleMaxFontSize(1200), 16);
  });

  group('TranslatorConfig', () {
    test('normalizes the base URL', () {
      expect(
        TranslatorConfig.normalizeBaseUrl(' api.openai.com/v1/ '),
        'https://api.openai.com/v1',
      );
      expect(
        TranslatorConfig.normalizeBaseUrl(
          'http://localhost:11434/v1/chat/completions',
        ),
        'http://localhost:11434/v1',
      );
      expect(TranslatorConfig.normalizeBaseUrl('  '), '');
    });

    test('defaults the language to the app language', () {
      const s = AppSettings(language: AppLanguage.indonesian);
      expect(TranslatorConfig.fromSettings(s).language, 'Indonesian');
      expect(
        TranslatorConfig.fromSettings(s.copyWith(translateLanguage: 'Japanese'))
            .language,
        'Japanese',
      );
    });

    test('reads the OCR script, Japanese/Chinese by default', () {
      const s = AppSettings();
      expect(TranslatorConfig.fromSettings(s).script, OcrScript.cjk);
      expect(
        TranslatorConfig.fromSettings(s.copyWith(translateScript: 'korean'))
            .script,
        OcrScript.korean,
      );
      expect(OcrScript.parse('unknown'), OcrScript.cjk);
    });

    test('auto reads by the source language', () {
      expect(OcrScript.forLanguage('ja'), OcrScript.cjk);
      expect(OcrScript.forLanguage('zh-hant'), OcrScript.cjk);
      expect(OcrScript.forLanguage('ko'), OcrScript.korean);
      expect(OcrScript.forLanguage('en'), OcrScript.english);
      expect(OcrScript.forLanguage('es'), OcrScript.latin);
      expect(
        OcrScript.english.detectSide,
        greaterThan(OcrScript.cjk.detectSide),
      );
      expect(OcrScript.forLanguage('id'), OcrScript.latin);
      expect(OcrScript.forLanguage('all'), OcrScript.cjk);
      expect(OcrScript.forLanguage(null), OcrScript.cjk);
      final auto = TranslatorConfig.fromSettings(const AppSettings());
      expect(auto.autoScript, isTrue);
      expect(
        auto.forComic('X', sourceLanguage: 'en').script,
        OcrScript.english,
      );
      final fixed = TranslatorConfig.fromSettings(
        const AppSettings(translateScript: 'korean'),
      );
      expect(
        fixed.forComic('X', sourceLanguage: 'en').script,
        OcrScript.korean,
      );
    });

    test('ML Kit translates from the source language', () {
      expect(mlKitSource('ja', OcrScript.latin), TranslateLanguage.japanese);
      expect(
        mlKitSource('pt-br', OcrScript.latin),
        TranslateLanguage.portuguese,
      );
      expect(mlKitSource('all', OcrScript.korean), TranslateLanguage.korean);
      expect(mlKitSource('', OcrScript.latin), TranslateLanguage.english);
      expect(mlKitTarget('Indonesian'), TranslateLanguage.indonesian);
      expect(mlKitTarget('Chinese (Simplified)'), TranslateLanguage.chinese);
      expect(mlKitTarget('Klingon'), isNull);
      final config = TranslatorConfig.configured(
        const AppSettings(translateEngine: 'mlkit'),
      )!.forComic('X', sourceLanguage: 'ja');
      expect(config.mlKit, isTrue);
      expect(config.cacheTag, startsWith('mlkit:ja|'));
    });

    test('configured only with a server and a model', () {
      const ready = AppSettings(
        translateBaseUrl: 'http://localhost:11434/v1',
        translateModel: 'qwen3:4b',
      );
      expect(TranslatorConfig.configured(ready), isNotNull);
      expect(
        TranslatorConfig.configured(ready.copyWith(translateModel: '')),
        isNull,
      );
      expect(TranslatorConfig.configured(const AppSettings()), isNull);
    });
  });
}
