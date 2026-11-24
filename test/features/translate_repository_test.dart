import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:yoru/core/network/network_info.dart';
import 'package:yoru/features/translate/data/datasources/llm_translator.dart';
import 'package:yoru/features/translate/data/datasources/translation_cache.dart';
import 'package:yoru/features/translate/data/ocr/paddle_ocr.dart';
import 'package:yoru/features/translate/data/ocr/text_grouping.dart';
import 'package:yoru/features/translate/data/repositories/translation_repository_impl.dart';
import 'package:yoru/features/translate/domain/entities/page_translation.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';

class _Online implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

class _Ocr implements PageOcr {
  @override
  Future<OcrPage> read(
    Uint8List bytes,
    OcrScript script, {
    Uint8List? above,
  }) async => (
    width: 600,
    height: 900,
    lines: [
      const OcrLine(rect: ui.Rect.fromLTWH(10, 10, 50, 20), text: 'HELLO'),
      // With the page above read on top: a line the seam cuts, and one
      // wholly above it (the page above's own).
      if (above != null) ...[
        const OcrLine(rect: ui.Rect.fromLTRB(200, -12, 400, 14), text: 'CUT'),
        const OcrLine(rect: ui.Rect.fromLTRB(450, -80, 560, -56), text: 'UP'),
      ],
    ],
  );
}

class _Llm implements LlmTranslator {
  final contexts = <List<String>>[];
  final sent = <List<String>>[];

  @override
  Future<List<String>> translate(
    List<String> texts, {
    required TranslatorConfig config,
    List<String> context = const [],
  }) async {
    contexts.add(context);
    sent.add(texts);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return [for (final t in texts) 'T:$t'];
  }
}

class _Cache implements TranslationCache {
  final _store = <String, PageTranslation>{};

  @override
  Future<PageTranslation?> get(String key) async => _store[key];

  @override
  Future<void> put(String key, PageTranslation translation) async =>
      _store[key] = translation;

  @override
  Future<void> remove(String key) async => _store.remove(key);
}

void main() {
  const config = TranslatorConfig(
    baseUrl: 'https://api.example.com/v1',
    apiKey: '',
    model: 'm',
    language: 'Indonesian',
  );

  test('pages asked together each get the one before as context, '
      'without waiting long', () async {
    final llm = _Llm();
    final repository = TranslationRepositoryImpl(
      _Online(),
      _Ocr(),
      llm,
      _Cache(),
    );
    Future<Uint8List> read() async => Uint8List(0);

    final watch = Stopwatch()..start();
    final results = await Future.wait([
      for (var i = 3; i >= 0; i--)
        repository.translate(
          pageId: 'p$i',
          readImage: read,
          config: config,
          previousPageId: i > 0 ? 'p${i - 1}' : null,
        ),
    ]).timeout(const Duration(seconds: 10));
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    expect(results.every((r) => r.isRight()), isTrue);
    // All but the first page read on from the one before.
    expect(llm.contexts.where((c) => c.isNotEmpty), hasLength(3));
  });

  test(
    'a forgotten page is translated again, its text not read again',
    () async {
      final llm = _Llm();
      final repository = TranslationRepositoryImpl(
        _Online(),
        _Ocr(),
        llm,
        _Cache(),
      );
      var reads = 0;
      Future<Uint8List> read() async {
        reads++;
        return Uint8List(0);
      }

      await repository.translate(pageId: 'p', readImage: read, config: config);
      expect(await repository.cached('p', config), isNotNull);
      await repository.forget(['p'], config);
      expect(await repository.cached('p', config), isNull);
      await repository.translate(pageId: 'p', readImage: read, config: config);
      expect(llm.contexts, hasLength(2));
      expect(reads, 1);
    },
  );

  test(
    'pages after the one on screen go in one request, each text once',
    () async {
      final llm = _Llm();
      final repository = TranslationRepositoryImpl(
        _Online(),
        _Ocr(),
        llm,
        _Cache(),
      );
      Future<Uint8List> read() async => Uint8List(0);

      repository.translateTogether([
        for (var i = 1; i <= 3; i++)
          (
            pageId: 'p$i',
            readImage: read,
            previousPageId: 'p${i - 1}',
            readPrevious: null,
          ),
      ], config);
      // A page asked for on its own joins the run.
      final joined = await repository.translate(
        pageId: 'p2',
        readImage: read,
        config: config,
      );
      expect(joined.isRight(), isTrue);
      for (var i = 1; i <= 3; i++) {
        expect(
          (await repository.cached('p$i', config))?.blocks.single.text,
          'T:HELLO',
        );
      }
      // One request; HELLO on all three pages sent once.
      expect(llm.sent, [
        ['HELLO'],
      ]);
    },
  );

  test(
    'a balloon cut by the seam is read whole and kept by the lower page',
    () async {
      final repository = TranslationRepositoryImpl(
        _Online(),
        _Ocr(),
        _Llm(),
        _Cache(),
      );
      Future<Uint8List> read() async => Uint8List(0);
      final joined = config.joined(true);

      await repository.translate(
        pageId: 'p2',
        readImage: read,
        config: joined,
        previousPageId: 'p1',
        readPrevious: read,
      );
      final page = (await repository.cached('p2', joined))!;
      expect(page.blocks.map((b) => b.text), ['T:CUT', 'T:HELLO']);
      expect(page.blocks.first.top, lessThan(0));

      // Not joined (pages one at a time): the page alone.
      await repository.translate(pageId: 'p2', readImage: read, config: config);
      expect(
        (await repository.cached('p2', config))!.blocks.map((b) => b.text),
        ['T:HELLO'],
      );
    },
  );
}
