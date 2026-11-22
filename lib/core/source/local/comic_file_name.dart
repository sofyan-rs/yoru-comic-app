/// What a comic file or folder name says: the series and the chapter (or
/// volume) number. `One Piece - Ch. 012.cbz` → `One Piece`, 12.
class ComicFileName {
  const ComicFileName({
    required this.series,
    this.number,
    this.isVolume = false,
  });

  /// Reads [name] (no folders; an extension is dropped).
  factory ComicFileName.parse(String name) {
    var base = name.trim();
    final dot = base.lastIndexOf('.');
    if (dot > 0 && base.length - dot <= 5) base = base.substring(0, dot);
    // Scanlator tags and years: `[Group]`, `(2020)`, `{v2}`.
    final cleaned = base
        .replaceAll(RegExp(r'\[[^\]]*\]|\([^)]*\)|\{[^}]*\}'), ' ')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    for (final (pattern, volume) in _numbered) {
      final match = pattern.firstMatch(cleaned);
      if (match == null) continue;
      final number = double.tryParse(match.group(2)!);
      if (number == null) continue;
      // `Vol. 2 Ch. 10`: the volume is not part of the series name.
      final before = (match.group(1) ?? '').replaceAll(
        RegExp(
          r'\b(?:v|vol|volume)\.?\s*\d+(?:\.\d+)?\s*$',
          caseSensitive: false,
        ),
        '',
      );
      return ComicFileName(
        series: _seriesOf(before, fallback: cleaned),
        number: number,
        isVolume: volume,
      );
    }
    return ComicFileName(series: _seriesOf(cleaned, fallback: base));
  }

  /// Series name; never empty.
  final String series;

  /// Chapter (or volume) number; null when the name has none.
  final double? number;

  /// [number] is a volume's (`Vol. 3`).
  final bool isVolume;

  /// `Ch. 12`, `Chapter 12.5`, `Episode 3`, `#4`, then `Vol. 2`, then a
  /// number at the end (`Title 012`). Group 1 is the text before.
  static final _numbered = [
    (
      RegExp(
        r'^(.*?)(?:\b(?:ch|chap|chapter|ep|episode)\.?|#)\s*(\d+(?:\.\d+)?)',
        caseSensitive: false,
      ),
      false,
    ),
    (
      RegExp(
        r'^(.*?)\b(?:v|vol|volume)\.?\s*(\d+(?:\.\d+)?)',
        caseSensitive: false,
      ),
      true,
    ),
    (RegExp(r'^(.*?\D)?(\d+(?:\.\d+)?)\s*$'), false),
  ];

  static String _seriesOf(String text, {required String fallback}) {
    final series = text
        .replaceAll(RegExp(r'[\s\-–—:,.]+$'), '')
        .replaceAll(RegExp(r'^[\s\-–—:,.]+'), '')
        .trim();
    if (series.isNotEmpty) return series;
    final rest = fallback.trim();
    return rest.isEmpty ? 'Untitled' : rest;
  }
}

/// The fields Yoru reads from a CBZ's `ComicInfo.xml` (the ComicRack
/// format most comic tools write).
class ComicInfo {
  const ComicInfo({
    this.series,
    this.title,
    this.number,
    this.volume,
    this.summary,
    this.authors = const [],
    this.genres = const [],
  });

  /// Parses [xml] loosely: missing or broken fields are left out.
  factory ComicInfo.parse(String xml) {
    String? field(String name) {
      final match = RegExp(
        '<$name>([\\s\\S]*?)</$name>',
        caseSensitive: false,
      ).firstMatch(xml);
      final value = match == null ? null : _unescape(match.group(1)!).trim();
      return value == null || value.isEmpty ? null : value;
    }

    List<String> list(String? value) => [
      for (final v in (value ?? '').split(RegExp(r'[,;]')))
        if (v.trim().isNotEmpty) v.trim(),
    ];

    final authors = <String>[];
    for (final name in ['Writer', 'Penciller', 'Artist']) {
      for (final a in list(field(name))) {
        if (!authors.contains(a)) authors.add(a);
      }
    }
    return ComicInfo(
      series: field('Series'),
      title: field('Title'),
      number: double.tryParse(field('Number') ?? ''),
      volume: double.tryParse(field('Volume') ?? ''),
      summary: field('Summary'),
      authors: authors,
      genres: list(field('Genre')),
    );
  }

  final String? series;
  final String? title;
  final double? number;
  final double? volume;
  final String? summary;

  /// Writers, then pencillers and artists, without repeats.
  final List<String> authors;
  final List<String> genres;

  static String _unescape(String text) => text
      .replaceAllMapped(
        RegExp(r'&#(x?)([0-9a-fA-F]+);'),
        (m) => String.fromCharCode(
          int.tryParse(m.group(2)!, radix: m.group(1)!.isEmpty ? 10 : 16) ??
              0x20,
        ),
      )
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}
