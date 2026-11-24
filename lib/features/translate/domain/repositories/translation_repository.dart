import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:yoru/core/error/failures.dart';
import 'package:yoru/features/translate/domain/entities/page_translation.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';

/// A page to translate: its URL or file path, how to read its image, and
/// the page before it (the context).
typedef PageRequest = ({
  String pageId,
  Future<Uint8List> Function() readImage,
  String? previousPageId,
});

abstract interface class TranslationRepository {
  /// Pages (ids) whose translation just finished, by whoever asked for it.
  Stream<String> get completed;

  /// The stored translation of [pageId] for [config], if there is one.
  Future<PageTranslation?> cached(String pageId, TranslatorConfig config);

  /// Drops the stored translations of [pageIds] for [config], so they are
  /// translated again; the text read off them is kept.
  Future<void> forget(Iterable<String> pageIds, TranslatorConfig config);

  /// Translates the page [pageId] (its URL or file path), reading the
  /// image with [readImage] only when no translation is stored. Requests
  /// for the same page share one run. The translation of [previousPageId]
  /// (waited for while it runs) is the context.
  /// Translates [pages] (in reading order) in one request, so the
  /// instructions and context are sent once for them all. Pages stored or
  /// already running are left alone; the others finish as [translate]'s
  /// do (on [completed]), and [translate] for one of them joins this run.
  void translateTogether(List<PageRequest> pages, TranslatorConfig config);

  Future<Either<Failure, PageTranslation>> translate({
    required String pageId,
    required Future<Uint8List> Function() readImage,
    required TranslatorConfig config,
    String? previousPageId,
  });
}
