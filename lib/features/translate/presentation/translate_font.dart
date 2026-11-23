import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yoru/core/assets/fonts.gen.dart';

/// Lettering of the translations: a bundled font ([builtinTranslateFonts],
/// Patrick Hand by default), or a font file the user imported (a commercial
/// comic font they own, say, which the app cannot ship).

/// Bundled fonts: the setting value (`AppSettings.translateFontPath`), the
/// family and the name. An empty setting is the first.
const builtinTranslateFonts = <(String, String, String)>[
  ('', FontFamily.patrickHand, 'Patrick Hand'),
  ('builtin:komika', FontFamily.komikaHand, 'Komika Hand'),
  ('builtin:comicneue', FontFamily.comicNeue, 'Comic Neue'),
];

/// Whether [setting] names a bundled font rather than an imported file.
bool isBuiltinTranslateFont(String setting) =>
    builtinTranslateFonts.any((f) => f.$1 == setting);

/// Families registered so far, by file path. Flutter cannot unload a font,
/// so each file gets a family of its own.
final _loaded = <String, Future<String?>>{};

/// The family to letter with for [path] (a bundled font's setting or an
/// imported file), registering a file on first use; null when the file is
/// unreadable (then the default shows).
Future<String?> translateFontFamily(String path) {
  for (final (setting, family, _) in builtinTranslateFonts) {
    if (setting == path) return SynchronousFuture(family);
  }
  return _loaded[path] ??= () async {
    try {
      final bytes = await File(path).readAsBytes();
      final family = 'YoruTranslate${_loaded.length}';
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      return family;
    } catch (e) {
      debugPrint('Translate font $path: $e');
      return null;
    }
  }();
}

/// Display name of a font setting: a bundled font's name, or the imported
/// file's name.
String translateFontName(String path) {
  for (final (setting, _, name) in builtinTranslateFonts) {
    if (setting == path) return name;
  }
  return path.split(RegExp(r'[\\/]')).last.replaceFirst(RegExp(r'^\d+-'), '');
}

/// Lets the user pick a .ttf or .otf file and copies it into the app's
/// support directory. Returns the copy's path, or null when cancelled.
/// Throws [FormatException] for another kind of file.
Future<String?> importTranslateFont() async {
  final files = await FilePicker.pickFiles(type: FileType.any);
  final source = files.firstOrNull?.path;
  if (source == null) return null;
  final name = source.split(RegExp(r'[\\/]')).last;
  if (!RegExp(r'\.(ttf|otf)$', caseSensitive: false).hasMatch(name)) {
    throw const FormatException('Not a .ttf or .otf font');
  }
  final dir = Directory(
    '${(await getApplicationSupportDirectory()).path}/fonts',
  );
  await dir.create(recursive: true);
  // A new name for every import: a family already registered for a path
  // keeps its glyphs, so a replaced file needs a path of its own.
  final target = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}-$name';
  await File(source).copy(target);
  return target;
}

/// Deletes an imported font file no longer in use; bundled ones are left.
Future<void> deleteTranslateFont(String path) async {
  if (isBuiltinTranslateFont(path)) return;
  try {
    await File(path).delete();
  } catch (_) {
    // Already gone.
  }
}
