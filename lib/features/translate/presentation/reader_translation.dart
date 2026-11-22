import 'dart:async';
import 'dart:io';

import 'package:yoru/core/di/injection.dart';
import 'package:yoru/core/network/image_cache.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';
import 'package:yoru/features/translate/domain/usecases/translate_page.dart';

/// Comics (by key) whose pages the reader translates, turned on from its
/// menu. Kept in memory only: it follows the reader from chapter to
/// chapter of the comic and is gone when the app closes.
final translatedComics = <String>{};

/// Pages after the one on screen translated in the background, so they are
/// ready (or nearly) when the reader gets there.
const translateAheadPages = 3;

/// Starts translating [pages] (URLs, or file paths when [isFile]) without
/// waiting. Pages already translated are read from the cache; a page whose
/// translation is running joins that run, so `TranslatedPage` shares it.
void translateAhead({
  required Iterable<String> pages,
  required bool isFile,
  required Map<String, String> headers,
  required TranslatorConfig? config,
}) {
  if (config == null) return;
  final translate = getIt<TranslatePage>();
  for (final page in pages) {
    unawaited(
      translate((
        pageId: page,
        readImage: () async => isFile
            ? File(page).readAsBytes()
            : (await comicImageCache.getSingleFile(
                page,
                key: page,
                headers: headers,
              )).readAsBytes(),
        config: config,
      )),
    );
  }
}
