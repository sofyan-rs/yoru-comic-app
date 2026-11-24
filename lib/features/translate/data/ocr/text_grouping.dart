import 'dart:math';
import 'dart:ui' show Rect;

/// One line (or, in vertical writing, one column) of text the OCR read,
/// in page pixels.
class OcrLine {
  const OcrLine({
    required this.rect,
    required this.text,
    this.score = 1,
    this.dark = false,
  });

  final Rect rect;
  final String text;
  final double score;

  /// On a dark background: its translation is lettered white on black.
  final bool dark;

  /// A column of vertical writing (Japanese, Chinese): much taller than
  /// wide. The recognizer reads it turned a quarter.
  bool get vertical => isVerticalBox(rect);

  @override
  String toString() => 'OcrLine($rect, $text)';
}

final _letter = RegExp(r'\p{L}', unicode: true);

/// A web address on its own (a scanlation site's watermark or credit), not
/// something a character says.
bool isWatermark(String text) => RegExp(
  r'^\W*(https?://)?(www\.)?[\w-]+(\.[\w-]+)*\.[a-z]{2,6}(/\S*)?\W*$',
  caseSensitive: false,
).hasMatch(text.trim());

final _credit = RegExp(
  r'discord|patreon|ko-?fi|paypal|saweria|trakteer|typeset|proofread|'
  r'redraw|clean(er|ing|ed)\b|translat(or|ed by|ion by)|scanlat|'
  r'\b(tl|pr|ts|qc|raws?|scans?)\b|join (us|our)|support us|donat',
  caseSensitive: false,
);

/// Scanlation credits or a plug (`TL: ...`, `Join our Discord`), not
/// story.
bool isCredit(String text) => _credit.hasMatch(text);

/// The blocks of a page worth translating: none on a credits page (two or
/// more [isCredit] blocks: a scanlator's staff or promo page), else all
/// but the credits.
List<OcrBlock> storyBlocks(List<OcrBlock> blocks) {
  final credits = blocks.where((b) => isCredit(b.text)).length;
  if (credits >= 2) return const [];
  return [
    for (final b in blocks)
      if (!isCredit(b.text)) b,
  ];
}

/// Whether a text box is a column of vertical writing.
bool isVerticalBox(Rect rect) => rect.height >= rect.width * 1.5;

/// The lines of one balloon or caption: what is translated as one piece.
class OcrBlock {
  const OcrBlock({
    required this.rect,
    required this.text,
    required this.letterSize,
    this.dark = false,
  });

  final Rect rect;
  final String text;

  /// Most of its lines are on a dark background.
  final bool dark;

  /// How big the original letters are, in page pixels: the usual height
  /// of its lines, or width of its columns.
  final double letterSize;

  @override
  String toString() => 'OcrBlock($rect, $text)';
}

/// Lines close together, running the same way, and lined up (the next line
/// of a balloon below, or the next column to its left) are one block.
/// Blocks come in reading order: top to bottom, and in a row, right to
/// left for vertical writing and left to right otherwise.
///
/// Lines that are not for translating are left out: a site's watermark
/// (`VORTEXSCANS.COM`), and blocks without a letter (`2`, `...`).
List<OcrBlock> groupLines(List<OcrLine> all) {
  final lines = withoutRuby(all).where((l) => !isWatermark(l.text)).toList();
  final parent = List<int>.generate(lines.length, (i) => i);
  int find(int i) {
    while (parent[i] != i) {
      parent[i] = parent[parent[i]];
      i = parent[i];
    }
    return i;
  }

  for (var i = 0; i < lines.length; i++) {
    for (var j = i + 1; j < lines.length; j++) {
      if (_together(lines[i], lines[j])) parent[find(i)] = find(j);
    }
  }

  final groups = <int, List<OcrLine>>{};
  for (var i = 0; i < lines.length; i++) {
    (groups[find(i)] ??= []).add(lines[i]);
  }

  final blocks = <OcrBlock>[];
  for (final group in groups.values) {
    final vertical = group.where((l) => l.vertical).length * 2 > group.length;
    // Columns right to left; lines top to bottom.
    group.sort(
      (a, b) => vertical
          ? b.rect.right.compareTo(a.rect.right)
          : a.rect.top.compareTo(b.rect.top),
    );
    final text = group
        .map((l) => l.text.trim())
        .where((t) => t.isNotEmpty)
        .reduce((a, b) => _join(a, b));
    if (!_letter.hasMatch(text)) continue;
    blocks.add(
      OcrBlock(
        rect: group.map((l) => l.rect).reduce((a, b) => a.expandToInclude(b)),
        text: text,
        letterSize: _median([
          for (final l in group) l.vertical ? l.rect.width : l.rect.height,
        ]),
        dark: group.where((l) => l.dark).length * 2 > group.length,
      ),
    );
  }

  final vertical = lines.where((l) => l.vertical).length * 2 > lines.length;
  blocks.sort((a, b) {
    // Same row when they overlap by half the shorter one's height.
    final overlap =
        min(a.rect.bottom, b.rect.bottom) - max(a.rect.top, b.rect.top);
    if (overlap > min(a.rect.height, b.rect.height) / 2) {
      return vertical
          ? b.rect.right.compareTo(a.rect.right)
          : a.rect.left.compareTo(b.rect.left);
    }
    return a.rect.top.compareTo(b.rect.top);
  });
  return blocks;
}

/// [lines] without ruby (furigana), the small reading set beside kanji,
/// which would mix into the text it glosses. On a page written mostly in
/// columns, a box under 60 % as wide as the usual column is ruby, a lone
/// ruby character (as tall as wide) included.
List<OcrLine> withoutRuby(List<OcrLine> lines) {
  final widths = [
    for (final l in lines)
      if (l.vertical) l.rect.width,
  ]..sort();
  if (widths.length < 3 || widths.length * 2 <= lines.length) return lines;
  final usual = widths[widths.length ~/ 2];
  return [
    for (final l in lines)
      if (l.rect.width >= usual * 0.6) l,
  ];
}

double _median(List<double> values) {
  final sorted = [...values]..sort();
  return sorted[sorted.length ~/ 2];
}

/// Whether [a] and [b] are lines of the same balloon.
bool _together(OcrLine a, OcrLine b) {
  if (a.vertical != b.vertical) return false;
  final ra = a.rect;
  final rb = b.rect;
  if (a.vertical) {
    // Neighbouring columns: a narrow gap side by side, overlapping in
    // height.
    final size = min(ra.width, rb.width);
    final gap = max(ra.left, rb.left) - min(ra.right, rb.right);
    final overlap = min(ra.bottom, rb.bottom) - max(ra.top, rb.top);
    // Lettering of one size: a caption beside a balloon is bigger.
    final widths = max(ra.width, rb.width) / min(ra.width, rb.width);
    return gap <= size * 0.9 &&
        overlap > min(ra.height, rb.height) * 0.3 &&
        widths < 1.6;
  }
  // Lines one under the other: a small gap, overlapping across.
  final size = min(ra.height, rb.height);
  final gap = max(ra.top, rb.top) - min(ra.bottom, rb.bottom);
  final overlap = min(ra.right, rb.right) - max(ra.left, rb.left);
  final heights = max(ra.height, rb.height) / min(ra.height, rb.height);
  return gap <= size * 0.9 &&
      overlap > min(ra.width, rb.width) * 0.2 &&
      heights < 2;
}

/// Joins two lines of a block: nothing between Chinese or Japanese text
/// (written without spaces), a word split by a hyphen at a line end joined
/// back, a space otherwise.
String _join(String a, String b) {
  if (_cjk.hasMatch(a.substring(a.length - 1)) || _cjk.hasMatch(b[0])) {
    return '$a$b';
  }
  if (a.endsWith('-') && !a.endsWith(' -')) {
    return '${a.substring(0, a.length - 1)}$b';
  }
  return '$a $b';
}

/// Han, kana and fullwidth forms.
final _cjk = RegExp(r'[　-ヿ㐀-鿿＀-￯]');
