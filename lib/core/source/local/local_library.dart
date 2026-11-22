import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yoru/core/source/local/comic_file_name.dart';

/// Page images a comic file may hold.
const localImageExtensions = {
  'jpg',
  'jpeg',
  'png',
  'webp',
  'gif',
  'avif',
  'bmp',
};

/// Comic files that import as chapters.
const localArchiveExtensions = {'cbz', 'zip'};

/// One imported chapter: its pages, extracted into [dir].
class LocalChapter {
  const LocalChapter({
    required this.number,
    required this.dir,
    required this.pages,
    required this.addedAt,
    this.title,
  });

  factory LocalChapter.fromJson(Map<String, dynamic> json) => LocalChapter(
    number: (json['number'] as num).toDouble(),
    title: json['title'] as String?,
    dir: json['dir'] as String,
    pages: (json['pages'] as List).cast<String>(),
    addedAt: DateTime.parse(json['addedAt'] as String),
  );

  final double number;
  final String? title;

  /// Folder in the series folder.
  final String dir;

  /// File names in [dir], in reading order.
  final List<String> pages;
  final DateTime addedAt;

  Map<String, dynamic> toJson() => {
    'number': number,
    'title': title,
    'dir': dir,
    'pages': pages,
    'addedAt': addedAt.toIso8601String(),
  };
}

/// One imported series, stored as `<root>/<slug>/series.json`.
class LocalSeries {
  LocalSeries({
    required this.slug,
    required this.title,
    required this.addedAt,
    required this.updatedAt,
    this.author,
    this.synopsis,
    this.genres = const [],
    this.cover,
    this.coverAt,
    this.aliases = const [],
    List<LocalChapter>? chapters,
  }) : chapters = chapters ?? [];

  factory LocalSeries.fromJson(Map<String, dynamic> json) => LocalSeries(
    slug: json['slug'] as String,
    title: json['title'] as String,
    author: json['author'] as String?,
    synopsis: json['synopsis'] as String?,
    genres: (json['genres'] as List?)?.cast<String>() ?? const [],
    cover: json['cover'] as String?,
    coverAt: DateTime.tryParse(json['coverAt'] as String? ?? ''),
    aliases: (json['aliases'] as List?)?.cast<String>() ?? const [],
    addedAt: DateTime.parse(json['addedAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    chapters: [
      for (final c in (json['chapters'] as List? ?? const []))
        LocalChapter.fromJson((c as Map).cast<String, dynamic>()),
    ],
  );

  final String slug;
  String title;
  String? author;
  String? synopsis;
  List<String> genres;

  /// File name of the cover in the series folder.
  String? cover;

  /// When [cover] last changed.
  DateTime? coverAt;

  /// Titles it had before an edit: imports under them still add to it.
  List<String> aliases;

  /// The user picked [cover] ([LocalLibrary.setCover]): imports keep it.
  bool get customCover => cover?.startsWith('cover-custom.') ?? false;
  final DateTime addedAt;
  DateTime updatedAt;

  /// Newest (highest number) first.
  final List<LocalChapter> chapters;

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'title': title,
    'author': author,
    'synopsis': synopsis,
    'genres': genres,
    'cover': cover,
    'coverAt': coverAt?.toIso8601String(),
    'aliases': aliases,
    'addedAt': addedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'chapters': [for (final c in chapters) c.toJson()],
  };

  /// Slug of the series titled [title]: ASCII (comic keys must be) and the
  /// same for the same title, so a later import adds to it.
  /// Whether [title] names this series (its title or an older one).
  bool isNamed(String title) {
    final t = title.trim().toLowerCase();
    return this.title.trim().toLowerCase() == t ||
        aliases.any((a) => a.trim().toLowerCase() == t);
  }

  static String slugFor(String title) {
    final normalized = title.trim().toLowerCase();
    var base = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (base.length > 60) base = base.substring(0, 60);
    if (base.isEmpty) base = 'comic';
    // FNV-1a: titles in other scripts slug to `comic`, the hash keeps them
    // apart.
    var hash = 0x811c9dc5;
    for (final unit in utf8.encode(normalized)) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return '$base-${hash.toRadixString(16).padLeft(8, '0')}';
  }
}

/// What an import did.
class LocalImportResult {
  const LocalImportResult({
    required this.chapters,
    required this.series,
    required this.slugs,
    required this.skipped,
  });

  /// Chapters added or replaced.
  final int chapters;

  /// Titles of the series that got chapters.
  final List<String> series;

  /// Their slugs, in the same order.
  final List<String> slugs;

  /// Files that were not imported, with why.
  final List<({String name, String reason})> skipped;
}

/// Comics imported from CBZ / ZIP files and image folders, kept in the
/// app's own storage (`<app support>/local`). Imports copy the pages out,
/// so the picked files can go away.
class LocalLibrary extends ChangeNotifier {
  LocalLibrary({Future<String> Function()? root})
    : _rootOf = root ?? _defaultRoot;

  static final instance = LocalLibrary();

  static Future<String> _defaultRoot() async =>
      '${(await getApplicationSupportDirectory()).path}/local';

  final Future<String> Function() _rootOf;
  Future<String>? _root;
  List<LocalSeries>? _series;

  /// Bumped on every import and delete, so screens showing the library
  /// know to load it again.
  int get revision => _revision;
  var _revision = 0;

  /// Folder holding one folder per series.
  Future<String> get root => _root ??= _rootOf();

  /// Every series, most recently updated first.
  Future<List<LocalSeries>> all() async {
    if (_series case final series?) return series;
    final dir = Directory(await root);
    final list = <LocalSeries>[];
    if (await dir.exists()) {
      await for (final entry in dir.list()) {
        if (entry is! Directory) continue;
        final file = File('${entry.path}/series.json');
        if (!await file.exists()) continue;
        try {
          list.add(
            LocalSeries.fromJson(
              jsonDecode(await file.readAsString()) as Map<String, dynamic>,
            ),
          );
        } catch (e) {
          debugPrint('Skipping unreadable local series ${entry.path}: $e');
        }
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return _series = list;
  }

  Future<LocalSeries?> find(String slug) async {
    for (final s in await all()) {
      if (s.slug == slug) return s;
    }
    return null;
  }

  /// Full path of [file] in the folder of the series [slug].
  Future<String> pathOf(String slug, String file) async =>
      '${await root}/$slug/$file';

  /// Imports CBZ / ZIP files and folders on another isolate; [into] the
  /// series of that slug, whatever their names say, when given.
  Future<LocalImportResult> import(List<String> paths, {String? into}) async {
    final root = await this.root;
    try {
      return await Isolate.run(() => importComics(root, paths, into: into));
    } finally {
      _changed();
    }
  }

  /// Changes the details of the series [slug]. Its slug stays, so its
  /// bookmark and history stay with it; a changed title is kept as an
  /// alias, so imports under the old one still add to it.
  Future<void> edit(
    String slug, {
    required String title,
    String? author,
    String? synopsis,
    List<String> genres = const [],
  }) async {
    final series = await _readSeries(slug);
    final clean = title.trim();
    if (clean.isNotEmpty && clean != series.title) {
      series.aliases = {
        ...series.aliases,
        series.title,
      }.where((a) => a.trim().toLowerCase() != clean.toLowerCase()).toList();
      series.title = clean;
    }
    series
      ..author = _blankToNull(author)
      ..synopsis = _blankToNull(synopsis)
      ..genres = [
        for (final g in genres)
          if (g.trim().isNotEmpty) g.trim(),
      ];
    await _writeSeries(series);
  }

  /// Makes the image at [path] the cover of the series [slug]; null goes
  /// back to the first page of its lowest chapter.
  Future<void> setCover(String slug, String? path) async {
    final series = await _readSeries(slug);
    final dir = await pathOf(slug, '');
    final old = series.cover;
    if (path == null) {
      if (!setFirstPageCover(dir, series)) return;
    } else {
      final cover = 'cover-custom.${_extension(path)}';
      await File(path).copy('$dir$cover');
      series.cover = cover;
    }
    if (old != null && old != series.cover) {
      final file = File('$dir$old');
      if (await file.exists()) await file.delete();
    }
    series.coverAt = DateTime.now();
    await _writeSeries(series);
  }

  Future<LocalSeries> _readSeries(String slug) async {
    final file = File(await pathOf(slug, 'series.json'));
    if (!await file.exists()) {
      throw const FileSystemException('This comic is no longer on this device');
    }
    return LocalSeries.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
  }

  Future<void> _writeSeries(LocalSeries series) async {
    await File(await pathOf(series.slug, 'series.json'))
        .writeAsString(jsonEncode(series.toJson()));
    _changed();
  }

  /// Removes the series [slug] and its files.
  Future<void> delete(String slug) async {
    final dir = Directory(await pathOf(slug, ''));
    if (await dir.exists()) await dir.delete(recursive: true);
    _changed();
  }

  void _changed() {
    _series = null;
    _revision++;
    notifyListeners();
  }
}

/// Imports [paths] (CBZ / ZIP files and folders) into [root]. Synchronous:
/// [LocalLibrary.import] runs it on another isolate.
@visibleForTesting
LocalImportResult importComics(
  String root,
  List<String> paths, {
  String? into,
  DateTime? now,
}) {
  final importer = _Importer(root, now ?? DateTime.now(), into: into);
  for (final path in paths) {
    try {
      if (FileSystemEntity.isDirectorySync(path)) {
        importer.addFolder(path);
      } else if (localArchiveExtensions.contains(_extension(path))) {
        importer.addArchive(path);
      } else {
        importer.skip(path, 'Not a CBZ or ZIP file');
      }
    } catch (e) {
      debugPrint('Local import of $path failed: $e');
      importer.skip(path, "Couldn't read this file");
    }
  }
  return importer.finish();
}

/// A page to write: [write] saves it to the path it is given.
typedef _Page = ({String name, void Function(String path) write});

class _Importer {
  _Importer(this.root, this.now, {this.into});

  final String root;
  final DateTime now;

  /// Slug of the series every chapter goes into, whatever its name.
  final String? into;

  /// Every series on disk, read once, to find one by an older title.
  late final List<LocalSeries> _existing = [
    if (Directory(root).existsSync())
      for (final dir in Directory(root).listSync().whereType<Directory>())
        ?_read(_baseName(dir.path)),
  ];
  final _touched = <String, LocalSeries>{};
  final _skipped = <({String name, String reason})>[];
  var _chapters = 0;

  void skip(String path, String reason) =>
      _skipped.add((name: _baseName(path), reason: reason));

  void addArchive(String path, {String? seriesHint}) {
    final input = InputFileStream(path);
    try {
      final archive = ZipDecoder().decodeStream(input);
      ComicInfo? info;
      final images = <ArchiveFile>[];
      for (final file in archive.files) {
        if (!file.isFile || _hidden(file.name)) continue;
        if (_baseName(file.name).toLowerCase() == 'comicinfo.xml') {
          final bytes = file.readBytes();
          if (bytes != null) {
            info = ComicInfo.parse(utf8.decode(bytes, allowMalformed: true));
          }
        } else if (localImageExtensions.contains(_extension(file.name))) {
          images.add(file);
        }
      }
      if (images.isEmpty) return skip(path, 'No images inside');

      _Page page(ArchiveFile file) => (
        name: file.name,
        write: (String to) {
          final out = OutputFileStream(to);
          try {
            file.writeContent(out);
          } finally {
            out.closeSync();
          }
        },
      );

      final name = ComicFileName.parse(_baseName(path));
      final series = info?.series ?? seriesHint ?? name.series;
      final groups = <String, List<ArchiveFile>>{};
      for (final file in images) {
        (groups[_dirName(file.name)] ??= []).add(file);
      }
      if (groups.length == 1) {
        // One chapter (or volume) per file.
        final number = info?.number ?? name.number ?? info?.volume;
        final isVolume =
            info?.number == null &&
            (name.isVolume || (name.number == null && info?.volume != null));
        _addChapter(
          series: series,
          info: info,
          number: number,
          title:
              info?.title ??
              (isVolume ? 'Volume ${_numberText(number!)}' : null),
          pages: [for (final f in images) page(f)],
        );
        return;
      }
      // A whole series: one folder per chapter.
      final dirs = groups.keys.toList()..sort(_naturalCompare);
      for (final (i, dir) in dirs.indexed) {
        final chapter = ComicFileName.parse(_baseName(dir));
        _addChapter(
          series: series,
          info: info,
          number: chapter.number ?? (i + 1).toDouble(),
          title: chapter.isVolume
              ? 'Volume ${_numberText(chapter.number!)}'
              : null,
          pages: [for (final f in groups[dir]!) page(f)],
        );
      }
    } finally {
      input.closeSync();
    }
  }

  /// A folder of images is a chapter; a folder of chapter folders or comic
  /// files is a series; a folder of series folders, a library.
  void addFolder(String path, {String? seriesHint}) {
    final entries = Directory(path).listSync()
      ..sort((a, b) => _naturalCompare(a.path, b.path));
    final images = [
      for (final e in entries)
        if (e is File &&
            !_hidden(_baseName(e.path)) &&
            localImageExtensions.contains(_extension(e.path)))
          e,
    ];
    final folders = [
      for (final e in entries)
        if (e is Directory && !_hidden(_baseName(e.path))) e,
    ];
    final archives = [
      for (final e in entries)
        if (e is File &&
            !_hidden(_baseName(e.path)) &&
            localArchiveExtensions.contains(_extension(e.path)))
          e,
    ];
    final name = ComicFileName.parse(_baseName(path));

    if (images.isNotEmpty) {
      _addChapter(
        series: seriesHint ?? name.series,
        number: name.number,
        title: name.isVolume ? 'Volume ${_numberText(name.number!)}' : null,
        pages: [for (final f in images) _filePage(f)],
      );
    }
    final series = seriesHint ?? _baseName(path);
    for (final (i, folder) in folders.indexed) {
      final folderImages = folder
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                !_hidden(_baseName(f.path)) &&
                localImageExtensions.contains(_extension(f.path)),
          )
          .toList();
      if (folderImages.isEmpty) {
        // A series folder in a library folder.
        if (seriesHint == null) addFolder(folder.path);
        continue;
      }
      folderImages.sort((a, b) => _naturalCompare(a.path, b.path));
      final chapter = ComicFileName.parse(_baseName(folder.path));
      _addChapter(
        series: series,
        number: chapter.number ?? (i + 1).toDouble(),
        title: chapter.isVolume
            ? 'Volume ${_numberText(chapter.number!)}'
            : null,
        pages: [for (final f in folderImages) _filePage(f)],
      );
    }
    for (final archive in archives) {
      try {
        addArchive(archive.path, seriesHint: series);
      } catch (e) {
        skip(archive.path, "Couldn't read this file");
      }
    }
    if (images.isEmpty && folders.isEmpty && archives.isEmpty) {
      skip(path, 'No images or comic files inside');
    }
  }

  _Page _filePage(File file) =>
      (name: file.path, write: (String to) => file.copySync(to));

  void _addChapter({
    required String series,
    required double? number,
    required String? title,
    required List<_Page> pages,
    ComicInfo? info,
  }) {
    final s = _series(series);
    final n = number ?? _nextNumber(s);
    final dir = 'ch-${_numberText(n)}';
    final seriesDir = '$root/${s.slug}';
    final temp = Directory('$seriesDir/.import-$dir');
    if (temp.existsSync()) temp.deleteSync(recursive: true);
    temp.createSync(recursive: true);
    final sorted = [...pages]..sort((a, b) => _naturalCompare(a.name, b.name));
    final names = <String>[];
    try {
      for (final (i, page) in sorted.indexed) {
        final name = '${i.toString().padLeft(3, '0')}.${_extension(page.name)}';
        page.write('${temp.path}/$name');
        names.add(name);
      }
      final target = Directory('$seriesDir/$dir');
      if (target.existsSync()) target.deleteSync(recursive: true);
      temp.renameSync(target.path);
    } catch (_) {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
      rethrow;
    }

    s.chapters
      ..removeWhere((c) => c.number == n)
      ..add(
        LocalChapter(
          number: n,
          title: title,
          dir: dir,
          pages: names,
          addedAt: now,
        ),
      )
      ..sort((a, b) => b.number.compareTo(a.number));
    if (info != null) {
      if (info.authors.isNotEmpty) s.author = info.authors.join(', ');
      if (info.summary != null) s.synopsis = info.summary;
      if (info.genres.isNotEmpty) s.genres = info.genres;
    }
    s.updatedAt = now;
    _chapters++;
  }

  LocalSeries _series(String title) {
    if (into case final into?) {
      return _touched[into] ??=
          _read(into) ??
          (throw const FileSystemException('This comic is no longer here'));
    }
    final slug = LocalSeries.slugFor(title);
    if (_touched[slug] case final touched?) return touched;
    for (final s in _touched.values) {
      if (s.isNamed(title)) return s;
    }
    final existing =
        _read(slug) ?? _existing.where((s) => s.isNamed(title)).firstOrNull;
    if (existing != null) return _touched[existing.slug] = existing;
    return _touched[slug] = LocalSeries(
      slug: slug,
      title: title,
      addedAt: now,
      updatedAt: now,
    );
  }

  LocalSeries? _read(String slug) {
    final file = File('$root/$slug/series.json');
    if (!file.existsSync()) return null;
    try {
      return LocalSeries.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  double _nextNumber(LocalSeries s) =>
      s.chapters.isEmpty ? 1 : s.chapters.first.number.floorToDouble() + 1;

  LocalImportResult finish() {
    for (final s in _touched.values) {
      _setCover(s);
      File('$root/${s.slug}/series.json')
        ..createSync(recursive: true)
        ..writeAsStringSync(jsonEncode(s.toJson()));
    }
    return LocalImportResult(
      chapters: _chapters,
      series: [for (final s in _touched.values) s.title],
      slugs: [for (final s in _touched.values) s.slug],
      skipped: _skipped,
    );
  }

  /// The first page of the lowest chapter, unless the user picked one.
  void _setCover(LocalSeries s) {
    if (s.customCover) return;
    final old = s.cover;
    final dir = '$root/${s.slug}/';
    if (!setFirstPageCover(dir, s)) return;
    if (old != null && old != s.cover) {
      final file = File('$dir$old');
      if (file.existsSync()) file.deleteSync();
    }
    s.coverAt = now;
  }
}

/// Copies the first page of [series]' lowest chapter to `cover.<ext>` in
/// its folder [dir] (ending in `/`). False when it has no pages.
bool setFirstPageCover(String dir, LocalSeries series) {
  final first = series.chapters.lastOrNull;
  if (first == null || first.pages.isEmpty) return false;
  final page = first.pages.first;
  final cover = 'cover.${_extension(page)}';
  File('$dir${first.dir}/$page').copySync('$dir$cover');
  series.cover = cover;
  return true;
}

String? _blankToNull(String? text) {
  final t = text?.trim();
  return t == null || t.isEmpty ? null : t;
}

/// `12` for 12.0, `12.5` for 12.5.
String _numberText(double n) =>
    n == n.truncateToDouble() ? n.toInt().toString() : n.toString();

String _baseName(String path) {
  final parts = path.split(RegExp(r'[/\\]'))..removeWhere((p) => p.isEmpty);
  return parts.isEmpty ? path : parts.last;
}

/// Folder part of an archive entry name; '' at the top.
String _dirName(String name) {
  final i = name.lastIndexOf('/');
  return i < 0 ? '' : name.substring(0, i);
}

String _extension(String path) {
  final name = _baseName(path);
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}

/// macOS metadata (`__MACOSX/`, `._x`) and hidden files.
bool _hidden(String path) => path
    .split(RegExp(r'[/\\]'))
    .any((p) => p.startsWith('.') && p != '.' && p != '..' || p == '__MACOSX');

/// Compares numbers in names by value: `page2` before `page10`.
int _naturalCompare(String a, String b) {
  final chunk = RegExp(r'\d+|\D+');
  final x = chunk.allMatches(a.toLowerCase()).map((m) => m[0]!).toList();
  final y = chunk.allMatches(b.toLowerCase()).map((m) => m[0]!).toList();
  for (var i = 0; i < x.length && i < y.length; i++) {
    final m = int.tryParse(x[i]);
    final n = int.tryParse(y[i]);
    final c = m != null && n != null ? m.compareTo(n) : x[i].compareTo(y[i]);
    if (c != 0) return c;
  }
  return x.length.compareTo(y.length);
}
