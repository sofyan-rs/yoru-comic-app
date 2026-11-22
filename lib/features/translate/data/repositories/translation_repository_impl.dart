import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:yoru/core/error/failures.dart';
import 'package:yoru/core/network/network_info.dart';
import 'package:yoru/core/network/remote_call.dart';
import 'package:yoru/features/translate/data/datasources/llm_translator.dart';
import 'package:yoru/features/translate/data/datasources/page_tiler.dart';
import 'package:yoru/features/translate/data/datasources/translation_cache.dart';
import 'package:yoru/features/translate/domain/entities/page_translation.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';
import 'package:yoru/features/translate/domain/repositories/translation_repository.dart';

@LazySingleton(as: TranslationRepository)
class TranslationRepositoryImpl implements TranslationRepository {
  TranslationRepositoryImpl(this._networkInfo, this._llm, this._cache);

  final NetworkInfo _networkInfo;
  final LlmTranslator _llm;
  final TranslationCache _cache;

  /// Model requests at once, across pages, so a local server is not
  /// flooded.
  static const _maxRequests = 3;
  int _running = 0;
  final _waiting = <Completer<void>>[];

  /// Runs in progress by cache key.
  final _inFlight = <String, Future<Either<Failure, PageTranslation>>>{};

  /// Bumped when stored translations should be made again (v2: boxes read
  /// on a square, see [modelCanvas]; v3: boxes around the lettering, not
  /// the bubble; v4: with the balloon).
  static const _version = 'v4';

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
  }) {
    final key = _key(pageId, config);
    return _inFlight[key] ??= _run(key, readImage, config)
        .then((result) {
          if (result.isRight()) _completed.add(pageId);
          return result;
        })
        .whenComplete(() => _inFlight.remove(key));
  }

  final _completed = StreamController<String>.broadcast();

  @override
  Stream<String> get completed => _completed.stream;

  Future<Either<Failure, PageTranslation>> _run(
    String key,
    Future<Uint8List> Function() readImage,
    TranslatorConfig config,
  ) async {
    if (await _cache.get(key) case final stored?) return right(stored);
    final local = _isLocal(config.baseUrl);
    return runRemote(_networkInfo, offline: local, () async {
      final watch = Stopwatch()..start();
      final bytes = await readImage();
      final read = watch.elapsedMilliseconds;
      final page = await tilePage(bytes);
      debugPrint(
        'Translate: page read in $read ms, ${page.tiles.length} tile(s) '
        'in ${watch.elapsedMilliseconds - read} ms; waiting: ${_waiting.length}',
      );
      final blocks = <TextBlock>[];
      final results = await Future.wait([
        for (final tile in page.tiles)
          _limited(
            () => _llm.translate(
              tile.png,
              width: modelCanvas,
              height: modelCanvas,
              config: config,
            ),
          ),
      ]);
      for (final (i, tile) in page.tiles.indexed) {
        blocks.addAll(placeOnPage(results[i], tile));
      }
      final translation = PageTranslation(aspect: page.aspect, blocks: blocks);
      await _cache.put(key, translation);
      return translation;
    });
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

/// [blocks] of [tile] in page fractions, without those whose centre lies in
/// the part of the tile another tile answers for.
///
/// [blocks] are in fractions of the [modelCanvas] square; the tile covers
/// its top left [PageTile.contentWidth] × [PageTile.contentHeight].
List<TextBlock> placeOnPage(List<TextBlock> blocks, PageTile tile) {
  final span = tile.bottom - tile.top;
  double x(double v) => (v / tile.contentWidth).clamp(0.0, 1.0);
  double y(double v) => (v / tile.contentHeight).clamp(0.0, 1.0);
  final placed = <TextBlock>[];
  for (final b in blocks) {
    // Blocks in the white margin are no text of the page.
    if (x(b.left) >= 1 || y(b.top) >= 1) continue;
    final top = tile.top + y(b.top) * span;
    final bottom = tile.top + y(b.bottom) * span;
    final centre = (top + bottom) / 2;
    final owned =
        centre >= tile.ownTop &&
        (centre < tile.ownBottom || tile.ownBottom >= 1);
    if (!owned) continue;
    placed.add(
      TextBlock(
        left: x(b.left),
        top: top,
        right: x(b.right),
        bottom: bottom,
        text: b.text,
        balloon: switch (b.balloon) {
          final o? => (
            left: x(o.left),
            top: tile.top + y(o.top) * span,
            right: x(o.right),
            bottom: tile.top + y(o.bottom) * span,
          ),
          null => null,
        },
      ),
    );
  }
  return placed;
}
