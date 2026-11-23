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
  Future<OcrPage> read(Uint8List bytes, OcrScript script) async => (
    width: 100,
    height: 150,
    lines: const [
      OcrLine(rect: ui.Rect.fromLTWH(10, 10, 50, 20), text: 'HELLO'),
    ],
  );
}

class _Llm implements LlmTranslator {
  final contexts = <List<String>>[];

  @override
  Future<List<String>> translate(
    List<String> texts, {
    required TranslatorConfig config,
    List<String> context = const [],
  }) async {
    contexts.add(context);
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
}
