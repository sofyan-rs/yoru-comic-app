import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:yoru/core/error/failures.dart';
import 'package:yoru/features/translate/domain/entities/page_translation.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';

abstract interface class TranslationRepository {
  /// Pages (ids) whose translation just finished, by whoever asked for it.
  Stream<String> get completed;

  /// The stored translation of [pageId] for [config], if there is one.
  Future<PageTranslation?> cached(String pageId, TranslatorConfig config);

  /// Translates the page [pageId] (its URL or file path), reading the
  /// image with [readImage] only when no translation is stored. Requests
  /// for the same page share one run. The translation of [previousPageId]
  /// (waited for while it runs) is the context.
  Future<Either<Failure, PageTranslation>> translate({
    required String pageId,
    required Future<Uint8List> Function() readImage,
    required TranslatorConfig config,
    String? previousPageId,
  });
}
