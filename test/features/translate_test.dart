import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:yoru/features/settings/domain/entities/app_settings.dart';
import 'package:yoru/features/translate/data/datasources/llm_translator.dart';
import 'package:yoru/features/translate/data/datasources/page_tiler.dart';
import 'package:yoru/features/translate/data/repositories/translation_repository_impl.dart';
import 'package:yoru/features/translate/domain/entities/page_translation.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';
import 'package:yoru/features/translate/presentation/widgets/translated_page.dart';

void main() {
  group('parseTextBlocks', () {
    test('reads 0-1000 boxes from {"blocks": [...]}', () {
      final blocks = parseTextBlocks(
        '{"blocks":[{"box":[100,200,500,400],"text":"Halo"}]}',
        width: 800,
        height: 1200,
      );
      expect(blocks, hasLength(1));
      expect(blocks.single.left, 0.1);
      expect(blocks.single.top, 0.2);
      expect(blocks.single.right, 0.5);
      expect(blocks.single.bottom, 0.4);
      expect(blocks.single.text, 'Halo');
    });

    test('reads the balloon around the lettering', () {
      final b = parseTextBlocks(
        '{"blocks":[{"balloon":[100,100,500,500],'
        '"box":[200,250,400,300],"text":"Hai"}]}',
        width: 1000,
        height: 1000,
      ).single;
      expect(b.left, 0.2);
      expect(b.balloon, (left: 0.1, top: 0.1, right: 0.5, bottom: 0.5));
      final json = TextBlock.fromJson(b.toJson());
      expect(json.balloon, b.balloon);
    });

    test('takes JSON out of a code fence and extra text', () {
      final blocks = parseTextBlocks(
        'Here you go:\n```json\n[{"bbox":[0,0,500,500],"translation":"A"}]\n```',
        width: 100,
        height: 100,
      );
      expect(blocks.single.text, 'A');
      expect(blocks.single.right, 0.5);
    });

    test('reads coordinates over 1000 as pixels', () {
      final blocks = parseTextBlocks(
        '{"blocks":[{"box":[0,600,400,1200],"text":"B"}]}',
        width: 800,
        height: 1200,
      );
      expect(blocks.single.right, 0.5);
      expect(blocks.single.top, 0.5);
      expect(blocks.single.bottom, 1);
    });

    test('orders swapped corners and skips empty or broken items', () {
      final blocks = parseTextBlocks(
        '{"blocks":['
        '{"box":[500,500,100,100],"text":"C"},'
        '{"box":[1,2,3],"text":"bad"},'
        '{"box":[0,0,100,100],"text":"  "}'
        ']}',
        width: 10,
        height: 10,
      );
      expect(blocks, hasLength(1));
      expect(blocks.single.left, 0.1);
      expect(blocks.single.right, 0.5);
    });

    test('no text is an empty list; no JSON throws', () {
      expect(parseTextBlocks('{"blocks":[]}', width: 1, height: 1), isEmpty);
      expect(
        () => parseTextBlocks('Sorry, I cannot.', width: 1, height: 1),
        throwsFormatException,
      );
    });
  });

  test('noThinking per server', () {
    expect(noThinking('https://api.deepseek.com/v1'), {
      'thinking': {'type': 'disabled'},
    });
    expect(noThinking('https://api.anthropic.com/v1'), isEmpty);
    expect(noThinking('https://api.openai.com/v1'), {
      'reasoning_effort': 'none',
    });
    expect(noThinking('http://localhost:11434/v1'), {
      'reasoning_effort': 'none',
    });
  });

  group('placeOnPage', () {
    final tile = PageTile(
      png: Uint8List(0),
      contentWidth: 1,
      contentHeight: 1,
      top: 0.25,
      bottom: 0.75,
      ownTop: 0.3,
      ownBottom: 0.7,
    );
    TextBlock block(double top, double bottom) =>
        TextBlock(left: 0, top: top, right: 1, bottom: bottom, text: 'x');

    test('maps tile fractions onto the page', () {
      final placed = placeOnPage([block(0.4, 0.6)], tile);
      expect(placed.single.top, closeTo(0.45, 1e-9));
      expect(placed.single.bottom, closeTo(0.55, 1e-9));
    });

    test('drops blocks centred in another tile\'s part', () {
      // Centre at 0.25 + 0.05 * 0.5 = 0.275 < ownTop.
      expect(placeOnPage([block(0, 0.1)], tile), isEmpty);
      // Centre at 0.725 >= ownBottom.
      expect(placeOnPage([block(0.9, 1)], tile), isEmpty);
    });

    test('reads boxes on the square, dropping the white margin', () {
      // A tile 2/3 as wide as tall fills the left 2/3 of the square.
      final narrow = PageTile(
        png: Uint8List(0),
        contentWidth: 2 / 3,
        contentHeight: 1,
        top: 0,
        bottom: 1,
        ownTop: 0,
        ownBottom: 1,
      );
      final placed = placeOnPage([
        const TextBlock(
          left: 1 / 3,
          top: 0.2,
          right: 2 / 3,
          bottom: 0.4,
          text: 'a',
        ),
        const TextBlock(
          left: 0.8,
          top: 0.2,
          right: 0.9,
          bottom: 0.4,
          text: 'b',
        ),
      ], narrow);
      expect(placed, hasLength(1));
      expect(placed.single.left, closeTo(0.5, 1e-9));
      expect(placed.single.right, closeTo(1, 1e-9));
      expect(placed.single.top, closeTo(0.2, 1e-9));
    });

    test('the last tile keeps blocks at the very bottom', () {
      final last = PageTile(
        png: Uint8List(0),
        contentWidth: 1,
        contentHeight: 1,
        top: 0.5,
        bottom: 1,
        ownTop: 0.6,
        ownBottom: 1,
      );
      expect(placeOnPage([block(0.9, 1)], last), hasLength(1));
    });
  });

  group('tilePage', () {
    test('a normal page is one tile on a 1000 px square', () async {
      final page = await tilePage(await _png(200, 300));
      expect(page.tiles, hasLength(1));
      expect(page.aspect, 1.5);
      final tile = page.tiles.single;
      expect(tile.contentHeight, 1);
      expect(tile.contentWidth, closeTo(2 / 3, 1e-9));
      final decoded = await ui.instantiateImageCodec(tile.png);
      final image = (await decoded.getNextFrame()).image;
      expect((image.width, image.height), (1000, 1000));
    });

    test(
      'a long strip is cut into overlapping tiles owning the whole page',
      () async {
        final page = await tilePage(await _png(200, 2000));
        expect(page.aspect, 10);
        expect(page.tiles.length, greaterThan(1));
        expect(page.tiles.first.top, 0);
        expect(page.tiles.last.bottom, 1);
        expect(page.tiles.first.ownTop, 0);
        expect(page.tiles.last.ownBottom, 1);
        for (var i = 1; i < page.tiles.length; i++) {
          final a = page.tiles[i - 1];
          final b = page.tiles[i];
          expect(b.top, lessThan(a.bottom), reason: 'tiles overlap');
          expect(b.ownTop, closeTo(a.ownBottom, 1e-9), reason: 'no gap');
        }
        for (final t in page.tiles) {
          expect(
            t.contentHeight / t.contentWidth,
            lessThanOrEqualTo(1.5 + 0.01),
          );
        }
      },
    );
  });

  group('layoutBubble', () {
    const bounds = ui.Rect.fromLTWH(0, 0, 800, 1200);

    test('grows the box a little and stays in the image', () {
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

    test('centres the box on its balloon when the letters are in it', () {
      // Letters found a little high in their balloon.
      const area = ui.Rect.fromLTWH(200, 200, 100, 40);
      const balloon = ui.Rect.fromLTWH(150, 150, 200, 200);
      final b = layoutBubble(area, 'HAI', bounds: bounds, balloon: balloon);
      expect((b.rect.center - balloon.center).distance, lessThan(1));
      expect(b.rect.width, closeTo(104, 1));
      // Letters outside the balloon: the balloon is not trusted.
      final away = layoutBubble(
        area,
        'HAI',
        bounds: bounds,
        balloon: const ui.Rect.fromLTWH(600, 600, 100, 100),
      );
      expect((away.rect.center - area.center).distance, lessThan(1));
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

  test('bubbleMaxFontSize follows the page width', () {
    expect(bubbleMaxFontSize(400), closeTo(11.2, 1e-9));
    expect(bubbleMaxFontSize(200), 9);
    expect(bubbleMaxFontSize(1200), 18);
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

    test('configured only with a server and a model', () {
      const ready = AppSettings(
        translateBaseUrl: 'http://localhost:11434/v1',
        translateModel: 'qwen2.5vl:3b',
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

/// A [width] × [height] PNG.
Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
