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
  static const _version = 'v12';

  /// Bumped when stored OCR text should be read again.
  static const _ocrVersion = 'ocr6';

  /// Translated lines of the page before sent as context, and their
  /// length: enough for names and tone, few tokens.
  static const _contextLines = 3;

  /// Texts sent in one request at most; more go in several.
  static const _maxTexts = 40;
  static const _contextLength = 80;

  static String _key(String pageId, TranslatorConfig config) =>
      '$_version|$pageId|${config.cacheTag}';

  @override
  Future<PageTranslation?> cached(String pageId, TranslatorConfig config) =>
      _cache.get(_key(pageId, config));

  @override
  Future<void> forget(Iterable<String> pageIds, TranslatorConfig config) =>
      Future.wait([for (final id in pageIds) _cache.remove(_key(id, config))]);

  @override
  Future<Either<Failure, PageTranslation>> translate({
    required String pageId,
    required Future<Uint8List> Function() readImage,
    required TranslatorConfig config,
    String? previousPageId,
    Future<Uint8List> Function()? readPrevious,
  }) {
    final key = _key(pageId, config);
    return _inFlight[key] ??
        _track(
          key,
          pageId,
          _run(key, pageId, readImage, config, previousPageId, readPrevious),
        );
  }

  /// [run] as the run of [pageId] under [key], until it ends: announced on
  /// [completed] when it succeeds.
  Future<Either<Failure, PageTranslation>> _track(
    String key,
    String pageId,
    Future<Either<Failure, PageTranslation>> run,
  ) => _inFlight[key] = run
      .then((result) {
        result.fold(
          (f) => debugPrint('Translate: page failed: ${f.message}'),
          (_) => _completed.add(pageId),
        );
        return result;
      })
      .whenComplete(() {
        // A block, not `=> remove(key)`: that returns this very future,
        // and whenComplete would wait for it forever.
        _inFlight.remove(key);
      });

  @override
  void translateTogether(List<PageRequest> pages, TranslatorConfig config) {
    final mine = <_Pending>[];
    for (final page in pages) {
      final key = _key(page.pageId, config);
      if (_inFlight.containsKey(key)) continue;
      final done = Completer<Either<Failure, PageTranslation>>();
      // Taken now, before any wait, so a page asking at once joins it.
      unawaited(_track(key, page.pageId, done.future));
      mine.add((page: page, key: key, done: done));
    }
    if (mine.isNotEmpty) unawaited(_runTogether(mine, config));
  }

  Future<void> _runTogether(
    List<_Pending> pages,
    TranslatorConfig config,
  ) async {
    final todo = <_Pending>[];
    for (final p in pages) {
      if (await _cache.get(p.key) case final stored?) {
        p.done.complete(right(stored));
      } else {
        todo.add(p);
      }
    }
    if (todo.isEmpty) return;
    final local = config.mlKit || _isLocal(config.baseUrl);
    final result = await runRemote(_networkInfo, offline: local, () async {
      final watch = Stopwatch()..start();
      final sources = [
        for (final p in todo)
          await _source(
            p.page.pageId,
            p.page.readImage,
            config.script,
            config.joinPages ? p.page.readPrevious : null,
          ),
      ];
      final read = watch.elapsedMilliseconds;
      final withText = <int>[];
      for (final (i, source) in sources.indexed) {
        if (source.blocks.isNotEmpty) {
          withText.add(i);
          continue;
        }
        final empty = PageTranslation(aspect: source.aspect, blocks: const []);
        await _cache.put(todo[i].key, empty);
        todo[i].done.complete(right(empty));
      }
      if (withText.isEmpty) return unit;
      final context = await _context(
        todo[withText.first].page.previousPageId,
        config,
      );
      final texts = [
        for (final i in withText)
          for (final b in sources[i].blocks) b.text,
      ];
      final translations = await _translateTexts(texts, config, context);
      debugPrint(
        'Translate: ${withText.length} pages together, ${texts.length} '
        'texts read in $read ms, translated in '
        '${watch.elapsedMilliseconds - read} ms',
      );
      var at = 0;
      for (final i in withText) {
        final n = sources[i].blocks.length;
        final translation = _translated(
          sources[i],
          translations.sublist(at, at + n),
        );
        at += n;
        await _cache.put(todo[i].key, translation);
        todo[i].done.complete(right(translation));
      }
      return unit;
    });
    for (final p in todo) {
      if (!p.done.isCompleted) {
        p.done.complete(
          result.fold(left, (_) => left(const ServerFailure('No translation'))),
        );
      }
    }
  }

  /// [texts] translated, each text once (a "..." or a cry repeated on a
  /// page is sent one time), at most [_maxTexts] a request.
  Future<List<String>> _translateTexts(
    List<String> texts,
    TranslatorConfig config,
    List<String> context,
  ) async {
    final unique = <String>[];
    final index = <String, int>{};
    final slots = [
      for (final t in texts)
        index.putIfAbsent(t, () {
          unique.add(t);
          return unique.length - 1;
        }),
    ];
    final out = <String>[];
    for (var from = 0; from < unique.length; from += _maxTexts) {
      final chunk = unique.sublist(from, min(from + _maxTexts, unique.length));
      out.addAll(
        await _limited(
          () => _llm.translate(chunk, config: config, context: context),
        ),
      );
    }
    return [for (final i in slots) out[i]];
  }

  /// [source]'s blocks with their [translations] (one each), leaving out
  /// those the model dropped.
  PageTranslation _translated(
    PageTranslation source,
    List<String> translations,
  ) {
    if (!kReleaseMode) {
      for (final (i, b) in source.blocks.indexed) {
        debugPrint('Translate:   ${b.text} -> ${translations[i]}');
      }
    }
    return PageTranslation(
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
    Future<Uint8List> Function()? readPrevious,
  ) async {
    if (await _cache.get(key) case final stored?) return right(stored);
    final local = config.mlKit || _isLocal(config.baseUrl);
    return runRemote(_networkInfo, offline: local, () async {
      final watch = Stopwatch()..start();
      final source = await _source(
        pageId,
        readImage,
        config.script,
        config.joinPages ? readPrevious : null,
      );
      final read = watch.elapsedMilliseconds;
      // Nothing to translate: no request, no waiting for the page before.
      if (source.blocks.isEmpty) {
        final empty = PageTranslation(aspect: source.aspect, blocks: const []);
        await _cache.put(key, empty);
        return empty;
      }
      final context = await _context(previousPageId, config);
      final translations = await _translateTexts(
        [for (final b in source.blocks) b.text],
        config,
        context,
      );
      debugPrint(
        'Translate: ${source.blocks.length} texts read in $read ms, '
        'translated in ${watch.elapsedMilliseconds - read} ms',
      );
      final translation = _translated(source, translations);
      await _cache.put(key, translation);
      return translation;
    });
  }

  /// The text of [pageId] as the OCR reads it (blocks holding the original
  /// text), stored apart from translations: another language or model
  /// translates it again without reading the page again.
  ///
  /// With [readPrevious], the bottom of the page before is read above it:
  /// a balloon the seam cuts is read whole and kept here (its top above
  /// 0), one wholly above the seam is the page before's own.
  Future<PageTranslation> _source(
    String pageId,
    Future<Uint8List> Function() readImage,
    OcrScript script, [
    Future<Uint8List> Function()? readPrevious,
  ]) async {
    final key =
        '$_ocrVersion|$pageId|${script.name}${readPrevious == null ? '' : '|j'}';
    if (await _cache.get(key) case final stored?) return stored;
    Uint8List? above;
    if (readPrevious != null) {
      try {
        above = await readPrevious();
      } catch (e) {
        // Not on the device yet: this page alone.
        debugPrint('Translate: page before unreadable: $e');
      }
    }
    final page = await _ocr.read(await readImage(), script, above: above);
    final source = PageTranslation(
      aspect: page.height / page.width,
      blocks: [
        for (final b in storyBlocks(
          groupLines(page.lines),
          pageWidth: page.width.toDouble(),
        ))
          if (b.rect.bottom > 0)
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

/// A page of [TranslationRepositoryImpl.translateTogether] not done yet.
typedef _Pending = ({
  PageRequest page,
  String key,
  Completer<Either<Failure, PageTranslation>> done,
});
