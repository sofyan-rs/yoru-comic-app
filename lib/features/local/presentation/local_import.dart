import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/di/injection.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/source/comic_key.dart';
import 'package:yoru/core/source/extension_manager.dart';
import 'package:yoru/core/source/local/local_library.dart';
import 'package:yoru/core/source/local/local_source.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:yoru/core/utils/utils.dart';
import 'package:yoru/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:yoru/features/comic_detail/domain/repositories/comic_detail_repository.dart';

/// Whether folders can be picked: iOS gives no lasting access to one.
bool get canImportFolders =>
    !kIsWeb && defaultTargetPlatform != TargetPlatform.iOS;

var _importing = false;

/// Asks for CBZ / ZIP files, or a folder where [canImportFolders], and
/// imports them into the local library, then bookmarks the series that got
/// chapters. With [into] (a local comic's key) every chapter goes into that
/// comic, whatever the files are named; [intoTitle] names it. True when
/// anything was imported.
Future<bool> importLocalComics(
  BuildContext context, {
  String? into,
  String? intoTitle,
}) async {
  if (_importing) {
    showSnackBar(context: context, message: AppText.t.importBusy);
    return false;
  }
  final folder = await _pickKind(context, intoTitle: intoTitle);
  if (folder == null || !context.mounted) return false;

  final paths = <String>[];
  final copies = <File>[];
  if (folder) {
    final dir = await FilePicker.getDirectoryPath(
      dialogTitle: AppText.t.importComics,
    );
    if (dir == null) return false;
    paths.add(dir);
  } else {
    final files = await FilePicker.pickFiles(
      dialogTitle: AppText.t.importComics,
    );
    if (files.isEmpty) return false;
    for (final file in files) {
      if (file.path case final path?) {
        paths.add(path);
      } else {
        // Not on disk (a content URI): copied first.
        final copy = await _copyToTemp(file);
        copies.add(copy);
        paths.add(copy.path);
      }
    }
  }
  if (!context.mounted) return false;

  _importing = true;
  final bookmarks = context.read<BookmarkCubit>();
  showSnackBar(
    context: context,
    message: AppText.t.importingComics,
    duration: const Duration(hours: 1),
  );
  LocalImportResult? result;
  try {
    result = await getIt<ExtensionManager>().local.import(
      paths,
      into: into == null ? null : ComicKey.slugOf(into),
    );
    await _bookmark(bookmarks, result.slugs);
  } catch (e) {
    debugPrint('Local import failed: $e');
  } finally {
    _importing = false;
    for (final copy in copies) {
      copy.delete().ignore();
    }
    if (!folder) FilePicker.clearTemporaryFiles().ignore();
  }
  if (context.mounted) {
    showSnackBar(
      context: context,
      message: _summary(result),
      duration: const Duration(seconds: 4),
    );
  }
  return (result?.chapters ?? 0) > 0;
}

/// Bookmarks the imported series not bookmarked yet: someone who imports
/// their files wants them in their library.
Future<void> _bookmark(BookmarkCubit bookmarks, List<String> slugs) async {
  final details = getIt<ComicDetailRepository>();
  for (final slug in slugs) {
    final key = ComicKey.of(LocalSource.id, slug);
    if (bookmarks.isBookmark(key)) continue;
    final result = await details.getComicDetails(key);
    await result.fold(
      (failure) async => debugPrint('Bookmarking $key failed: $failure'),
      (comic) => bookmarks.addBookmark(comic, key),
    );
  }
}

String _summary(LocalImportResult? result) {
  if (result == null) return AppText.t.importFailed;
  final skipped = result.skipped;
  if (result.chapters == 0) {
    return skipped.length == 1
        ? '${skipped.single.name}: ${skipped.single.reason}'
        : skipped.isEmpty
        ? AppText.t.importNothing
        : '${AppText.t.importNothing} · ${AppText.t.importSkipped(skipped.length)}';
  }
  final done = AppText.t.imported(result.chapters, result.series.length);
  return skipped.isEmpty
      ? done
      : '$done · ${AppText.t.importSkipped(skipped.length)}';
}

Future<File> _copyToTemp(PlatformFile file) async {
  final dir = await Directory(
    '${(await getTemporaryDirectory()).path}/local-import',
  ).create(recursive: true);
  final copy = File(
    '${dir.path}/${DateTime.now().microsecondsSinceEpoch}-${file.name}',
  );
  final sink = copy.openWrite();
  try {
    await sink.addStream(file.readAsByteStream());
  } finally {
    await sink.close();
  }
  return copy;
}

/// How to name files, then files or a folder: true for a folder, false for
/// files, null when dismissed. [intoTitle]: chapters for that comic.
Future<bool?> _pickKind(BuildContext context, {String? intoTitle}) =>
    showDotSheet<bool>(
      context: context,
      builder: (context) {
        final c = Dotline.of(context);
        final hint = DotlineText.bodyS.copyWith(color: c.inkMuted);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActionSheetHeader(
              icon: intoTitle == null
                  ? LucideIcons300.folderInput
                  : LucideIcons300.filePlus,
              title: intoTitle == null
                  ? AppText.t.importComics
                  : AppText.t.addChapters,
              subtitle: intoTitle,
            ),
            const SizedBox(height: DotSpace.s4),
            if (intoTitle == null) ...[
              Text(AppText.t.importNamingTitle, style: DotlineText.label),
              const SizedBox(height: DotSpace.s2),
              Text(AppText.t.importNaming, style: hint),
              const SizedBox(height: DotSpace.s2),
              Text(
                AppText.t.importNamingExamples,
                style: hint.copyWith(fontFamily: DotlineText.data.fontFamily),
              ),
              if (canImportFolders) ...[
                const SizedBox(height: DotSpace.s2),
                Text(AppText.t.importFolderHint, style: hint),
              ],
            ] else
              Text(AppText.t.addChaptersHint, style: hint),
            const SizedBox(height: DotSpace.s5),
            DotButton(
              label: AppText.t.importFiles,
              onTap: () => Navigator.of(context).pop(false),
            ),
            if (canImportFolders) ...[
              const SizedBox(height: DotSpace.s3),
              DotButton.outline(
                label: AppText.t.importFolder,
                onTap: () => Navigator.of(context).pop(true),
              ),
            ],
          ],
        );
      },
    );
