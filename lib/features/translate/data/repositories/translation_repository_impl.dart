import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:yoru/core/error/failures.dart';
import 'package:yoru/core/network/network_info.dart';
import 'package:yoru/core/network/remote_call.dart';
import 'package:yoru/features/translate/data/datasources/llm_translator.dart';
import 'package:yoru/features/translate/data/datasources/translation_cache.dart';
import 'package:yoru/features/translate/data/ocr/paddle_ocr.dart';
import 'package:yoru/features/translate/data/ocr/text_grouping.dart';
import 'package:yoru/features/translate/domain/entities/page_translation.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';
import 'package:yoru/features/translate/domain/repositories/translation_repository.dart';

@LazySingleton(as: TranslationRepository)
class TranslationRepositoryImpl implements TranslationRepository {
  TranslationRepositoryImpl(
    this._networkInfo,
    this._ocr,
    this._llm,
    this._cache,
  );

  final NetworkInfo _networkInfo;
  final PageOcr _ocr;
  final LlmTranslator _llm;
  final TranslationCache _cache;

  /// Model requests at once, across pages, so a local server is not
  /// flooded.
  static const _maxRequests = 3;
  int _running = 0;
  final _waiting = <Completer<void>>[];

  /// Runs in progress by cache key.
  final _inFlight = <String, Future<Either<Failure, PageTranslation>>>{};

  /// Bumped when stored translations should be made again (v5: read by
  /// OCR in the app instead of by the model; v6: texts sent by number; v7:
  /// with the letters' size; v8: a style guide per language; v9: aku/kamu,
  /// never gue/lo).
  static const _version = 'v10';

  /// Bumped when stored OCR text should be read again.
  static const _ocrVersion = 'ocr4';

  /// Translated lines of the page before sent as context, and their
  /// length: enough for names and tone, few tokens.
  static const _contextLines = 6;
  static const _contextLength = 80;

  static String _key(String pageId, TranslatorConfig config) =>
      '$_version|$pageId|${config.cacheTag}';

  @override
  Future<PageTranslation?> cached(String pageId, TranslatorConfig config) =>
      _cache.get(_key(pageId, config));

  @override
  Future<Either<Failure, PageTranslation>> translate({
    required String pageId,
    required Future<Uint8List> Function() readImage,
    required TranslatorConfig config,
    String? previousPageId,
  }) {
    final key = _key(pageId, config);
    return _inFlight[key] ??=
        _run(key, pageId, readImage, config, previousPageId)
            .then((result) {
              result.fold(
                (f) => debugPrint('Translate: page failed: ${f.message}'),
                (_) => _completed.add(pageId),
              );
              return result;
            })
            .whenComplete(() {
              // A block, not `=> remove(key)`: that returns this very
              // future, and whenComplete would wait for it forever.
              _inFlight.remove(key);
            });
  }

  final _completed = StreamController<String>.broadcast();

  @override
  Stream<String> get completed => _completed.stream;

  Future<Either<Failure, PageTranslation>> _run(
    String key,
    String pageId,
    Future<Uint8List> Function() readImage,
    TranslatorConfig config,
    String? previousPageId,
  ) async {
    if (await _cache.get(key) case final stored?) return right(stored);
    final local = config.mlKit || _isLocal(config.baseUrl);
    return runRemote(_networkInfo, offline: local, () async {
      final watch = Stopwatch()..start();
      final source = await _source(pageId, readImage, config.script);
      final read = watch.elapsedMilliseconds;
      // Nothing to translate: no request, no waiting for the page before.
      if (source.blocks.isEmpty) {
        final empty = PageTranslation(aspect: source.aspect, blocks: const []);
        await _cache.put(key, empty);
        return empty;
      }
      final context = await _context(previousPageId, config);
      final translations = await _limited(
        () => _llm.translate(
          [for (final b in source.blocks) b.text],
          config: config,
          context: context,
        ),
      );
      debugPrint(
        'Translate: ${source.blocks.length} texts read in $read ms, '
        'translated in ${watch.elapsedMilliseconds - read} ms',
      );
      final translation = PageTranslation(
        aspect: source.aspect,
        blocks: [
          for (final (i, b) in source.blocks.indexed)
            if (translations[i].isNotEmpty)
              TextBlock(
                left: b.left,
                top: b.top,
                right: b.right,
                bottom: b.bottom,
                text: translations[i],
                letterSize: b.letterSize,
                dark: b.dark,
              ),
        ],
      );
      if (!kReleaseMode) {
        for (final (i, b) in source.blocks.indexed) {
          debugPrint('Translate:   ${b.text} -> ${translations[i]}');
        }
      }
      await _cache.put(key, translation);
      return translation;
    });
  }

  /// The text of [pageId] as the OCR reads it (blocks holding the original
  /// text), stored apart from translations: another language or model
  /// translates it again without reading the page again.
  Future<PageTranslation> _source(
    String pageId,
    Future<Uint8List> Function() readImage,
    OcrScript script,
  ) async {
    final key = '$_ocrVersion|$pageId|${script.name}';
    if (await _cache.get(key) case final stored?) return stored;
    final page = await _ocr.read(await readImage(), script);
    final source = PageTranslation(
      aspect: page.height / page.width,
      blocks: [
        for (final b in storyBlocks(groupLines(page.lines)))
          TextBlock(
            left: b.rect.left / page.width,
            top: b.rect.top / page.height,
            right: b.rect.right / page.width,
            bottom: b.rect.bottom / page.height,
            text: b.text,
            letterSize: b.letterSize / page.width,
            dark: b.dark,
          ),
      ],
    );
    await _cache.put(key, source);
    return source;
  }

  /// The last lines of [previousPageId]'s translation, waiting for it while
  /// it runs, so a page reads on from the one before (names, forms of
  /// address, tone).
  Future<List<String>> _context(
    String? previousPageId,
    TranslatorConfig config,
  ) async {
    if (previousPageId == null) return const [];
    final key = _key(previousPageId, config);
    if (_inFlight[key] case final running?) {
      await running
          .timeout(const Duration(seconds: 60))
          .then((_) {}, onError: (Object _) {});
    }
    final previous = await _cache.get(key);
    if (previous == null) return const [];
    final lines = previous.blocks.map((b) => b.text).toList();
    return [
      for (final l in lines.skip(max(0, lines.length - _contextLines)))
        l.length > _contextLength ? '${l.substring(0, _contextLength)}…' : l,
    ];
  }

  Future<T> _limited<T>(Future<T> Function() call) async {
    if (_running >= _maxRequests) {
      final turn = Completer<void>();
      _waiting.add(turn);
      await turn.future;
    }
    _running++;
    try {
      return await call();
    } finally {
      _running--;
      if (_waiting.isNotEmpty) _waiting.removeAt(0).complete();
    }
  }

  /// A server on this device or the local network works without internet.
  static bool _isLocal(String baseUrl) {
    final host = Uri.tryParse(baseUrl)?.host ?? '';
    return host == 'localhost' ||
        host.endsWith('.local') ||
        RegExp(r'^(127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)')
            .hasMatch(host);
  }
}
