import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:yoru/core/di/injection.dart';
import 'package:yoru/core/network/image_cache.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';
import 'package:yoru/features/translate/domain/usecases/translate_page.dart';

/// Comics (by key) whose pages the reader translates, turned on from its
/// menu. Kept in memory only: it follows the reader from chapter to
/// chapter of the comic and is gone when the app closes.
final translatedComics = <String>{};

/// Pages after the one on screen translated too, so they are ready (or
/// nearly) when the reader gets there: with the page on screen, at most
/// four pages are translated at a time, not the whole chapter.
const translateAheadPages = 3;

/// Pages (ids) the reader wants translated now: the one on screen, the one
/// before it and [translateAheadPages] after. A page outside it shows a
/// stored translation but asks for none.
final translateWindow = ValueNotifier<Set<String>>(const {});

/// Sets [translateWindow] around [page] of [pages] (URLs, or file paths
/// when [isFile]) and starts translating the page and the next ones, in
/// order, each with the one before as its context. Pages already
/// translated are read from the cache; a page whose translation is running
/// joins that run, so `TranslatedPage` shares it.
void translateAhead({
  required List<String> pages,
  required int page,
  required bool isFile,
  required Map<String, String> headers,
  required TranslatorConfig? config,
}) {
  if (config == null || pages.isEmpty) return;
  final from = page.clamp(0, pages.length - 1);
  final to = min(pages.length, from + 1 + translateAheadPages);
  translateWindow.value = {
    for (var i = max(0, from - 1); i < to; i++) pages[i],
  };
  final translate = getIt<TranslatePage>();
  for (var i = from; i < to; i++) {
    final id = pages[i];
    unawaited(
      translate((
        pageId: id,
        readImage: () => readPage(id, isFile: isFile, headers: headers),
        config: config,
        previousPageId: i > 0 ? pages[i - 1] : null,
      )),
    );
  }
}

/// The bytes of a page: the file, or the copy the image cache keeps.
Future<Uint8List> readPage(
  String page, {
  required bool isFile,
  required Map<String, String> headers,
}) async => isFile
    ? File(page).readAsBytes()
    : (await comicImageCache.getSingleFile(
        page,
        key: page,
        headers: headers,
      )).readAsBytes();
