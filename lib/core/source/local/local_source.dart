import 'package:yoru/core/error/exceptions.dart';
import 'package:yoru/core/source/extension_meta.dart';
import 'package:yoru/core/source/extension_runtime.dart';
import 'package:yoru/core/source/local/local_library.dart';

/// Error of [LocalSource.browse] while nothing is imported; Home and Explore
/// show an import button for it.
const localEmptyMessage = 'No comics on this device yet.';

/// The built-in source of comics imported from files ([LocalLibrary]). It
/// answers the same methods as an extension (`browse`, `series`,
/// `chapters`, `chapter`), so everything above [SourceBackend] treats it
/// like any other source; it needs no connection.
///
/// Covers are `local://<slug>/<file>` URLs that the image caches read from
/// disk; pages are file paths, read like downloaded chapters.
class LocalSource implements LoadedSource {
  LocalSource(this._library);

  static const id = 'local';

  /// [ExtensionMeta] of the source; it is always installed.
  static const info = ExtensionMeta(
    id: id,
    name: 'Local',
    lang: 'all',
    version: '1.0.0',
    apiVersion: 1,
    baseUrl: '',
    file: '',
    sha256: '',
  );

  /// Scheme of cover URLs.
  static const scheme = 'local';

  static bool isLocalKey(String sourceId) => sourceId == id;

  final LocalLibrary _library;

  @override
  ExtensionMeta get meta => info;

  @override
  void dispose() {}

  static const _sortKey = 'sort';

  @override
  Future<SourceFeatures> features() async => SourceFeatures.fromJson(
    // One section on Home: with few comics, newest series and latest
    // chapters would mostly repeat each other. `featured: null` hides the
    // first (as for Mihon); Explore still sorts by date added.
    home: {
      'featured': null,
      'latest': {
        _sortKey: ['updated'],
      },
      'latestLabel': 'Recently updated',
    },
    groups: [
      {
        'key': _sortKey,
        'label': 'Sort',
        'type': 'select',
        'options': [
          {'value': 'updated', 'label': 'Recently updated'},
          {'value': 'added', 'label': 'Recently added'},
          {'value': 'title', 'label': 'Title'},
        ],
      },
    ],
  );

  @override
  Future<Object?> call(String method, List<Object?> args) async {
    switch (method) {
      case 'browse':
        return _browse(args.firstOrNull is Map ? args.first! as Map : const {});
      case 'series':
        return _seriesDetail(await _find(args));
      case 'chapters':
        final series = await _find(args);
        return [
          for (final c in series.chapters)
            {'number': c.number, 'createdAt': c.addedAt.toIso8601String()},
        ];
      case 'chapter':
        return _chapter(await _find(args), args.elementAtOrNull(1));
      case 'webUrl':
        return '';
    }
    throw ServerException('Local comics have no "$method"');
  }

  Future<Map<String, Object?>> _browse(Map params) async {
    final all = await _library.all();
    if (all.isEmpty) throw const ServerException(localEmptyMessage);
    final query = '${params['query'] ?? ''}'.trim().toLowerCase();
    final filters = params['filters'];
    final sort = filters is Map && filters[_sortKey] is List
        ? (filters[_sortKey] as List).firstOrNull
        : null;
    final items = [
      for (final s in all)
        if (query.isEmpty || s.title.toLowerCase().contains(query)) s,
    ];
    switch (sort) {
      case 'added':
        items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      case 'title':
        items.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      default:
        items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    final page = (params['page'] as num?)?.toInt() ?? 1;
    final limit = (params['limit'] as num?)?.toInt() ?? 30;
    final start = (page - 1) * limit;
    return {
      'items': [for (final s in items.skip(start).take(limit)) _series(s)],
      'hasNext': start + limit < items.length,
    };
  }

  Future<LocalSeries> _find(List<Object?> args) async {
    final slug = '${args.firstOrNull}';
    final series = await _library.find(slug);
    if (series == null) {
      throw const ServerException(
        '404 This comic is no longer on this device',
        statusCode: 404,
      );
    }
    return series;
  }

  /// `local://<slug>/cover.jpg?v=<changed>`: the version makes the image
  /// caches read a cover again after it changed.
  static String? coverUrl(LocalSeries s) => s.cover == null
      ? null
      : '$scheme://${s.slug}/${s.cover}'
            '?v=${(s.coverAt ?? s.updatedAt).millisecondsSinceEpoch}';

  Map<String, Object?> _series(LocalSeries s) => {
    'slug': s.slug,
    'title': s.title,
    'cover': coverUrl(s),
    'format': null,
    'status': null,
    'rating': null,
    'totalChapters': s.chapters.length,
  };

  Map<String, Object?> _seriesDetail(LocalSeries s) => {
    ..._series(s),
    'nativeTitle': null,
    'releaseDate': null,
    'author': s.author,
    'synopsis': s.synopsis,
    'genres': [
      for (final g in s.genres) {'id': g, 'name': g},
    ],
  };

  Future<Map<String, Object?>> _chapter(LocalSeries s, Object? number) async {
    final n = number is num ? number.toDouble() : double.tryParse('$number');
    // Newest first: the previous chapter comes after, the next before.
    final i = s.chapters.indexWhere((c) => c.number == n);
    if (i < 0) {
      throw const ServerException(
        '404 This chapter is no longer on this device',
        statusCode: 404,
      );
    }
    final chapter = s.chapters[i];
    final dir = await _library.pathOf(s.slug, chapter.dir);
    return {
      'number': chapter.number,
      'title': chapter.title,
      'prev': s.chapters.elementAtOrNull(i + 1)?.number,
      'next': i > 0 ? s.chapters[i - 1].number : null,
      'images': [for (final p in chapter.pages) '$dir/$p'],
    };
  }
}
