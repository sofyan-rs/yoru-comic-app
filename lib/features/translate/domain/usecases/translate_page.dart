import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:yoru/core/error/failures.dart';
import 'package:yoru/core/usecase/usecase.dart';
import 'package:yoru/features/translate/domain/entities/page_translation.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';
import 'package:yoru/features/translate/domain/repositories/translation_repository.dart';

typedef TranslatePageParams = ({
  String pageId,
  Future<Uint8List> Function() readImage,
  TranslatorConfig config,

  /// The page before, whose translation is the context.
  String? previousPageId,
});

/// Translates one chapter page, from the cache when it was done before.
@injectable
class TranslatePage implements UseCase<PageTranslation, TranslatePageParams> {
  const TranslatePage(this._repository);

  final TranslationRepository _repository;

  /// Pages (ids) whose translation just finished, whoever asked for it:
  /// a page still waiting can read it from the cache.
  Stream<String> get completed => _repository.completed;

  /// A stored translation, without any request.
  Future<PageTranslation?> cached(String pageId, TranslatorConfig config) =>
      _repository.cached(pageId, config);

  /// Translates [pages] in one request (see
  /// [TranslationRepository.translateTogether]).
  void together(List<PageRequest> pages, TranslatorConfig config) =>
      _repository.translateTogether(pages, config);

  /// Drops stored translations, so the pages are translated again.
  Future<void> forget(Iterable<String> pageIds, TranslatorConfig config) =>
      _repository.forget(pageIds, config);

  @override
  Future<Either<Failure, PageTranslation>> call(TranslatePageParams p) =>
      _repository.translate(
        pageId: p.pageId,
        readImage: p.readImage,
        config: p.config,
        previousPageId: p.previousPageId,
      );
}
