/// A rectangle in fractions of the page.
typedef PageBox = ({double left, double top, double right, double bottom});

/// One piece of text on a page and its translation. The box (around the
/// original lettering) and [balloon] are in fractions of the page (0 at the
/// left/top, 1 at the right/bottom), so they fit the page at any size it
/// is shown.
class TextBlock {
  const TextBlock({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.text,
    this.balloon,
  });

  factory TextBlock.fromJson(Map<String, dynamic> json) => TextBlock(
    left: (json['l'] as num).toDouble(),
    top: (json['t'] as num).toDouble(),
    right: (json['r'] as num).toDouble(),
    bottom: (json['b'] as num).toDouble(),
    text: json['text'] as String,
    balloon: switch (json['balloon']) {
      [final num l, final num t, final num r, final num b] => (
        left: l.toDouble(),
        top: t.toDouble(),
        right: r.toDouble(),
        bottom: b.toDouble(),
      ),
      _ => null,
    },
  );

  final double left;
  final double top;
  final double right;
  final double bottom;

  /// The translated text.
  final String text;

  /// The speech balloon or caption box the lettering is in, when the model
  /// gave one. Models place a balloon more reliably than its lettering, and
  /// lettering sits in the middle of it.
  final PageBox? balloon;

  double get width => right - left;
  double get height => bottom - top;

  Map<String, dynamic> toJson() => {
    'l': left,
    't': top,
    'r': right,
    'b': bottom,
    'text': text,
    if (balloon case final b?) 'balloon': [b.left, b.top, b.right, b.bottom],
  };

  @override
  String toString() => 'TextBlock($left, $top, $right, $bottom, $text)';
}

/// The translated text of one page.
class PageTranslation {
  const PageTranslation({required this.aspect, required this.blocks});

  factory PageTranslation.fromJson(Map<String, dynamic> json) =>
      PageTranslation(
        aspect: (json['aspect'] as num).toDouble(),
        blocks: [
          for (final b in json['blocks'] as List)
            TextBlock.fromJson(b as Map<String, dynamic>),
        ],
      );

  /// Height over width of the page image, to place [blocks] on it when it
  /// is shown letterboxed (fitted to height).
  final double aspect;

  final List<TextBlock> blocks;

  Map<String, dynamic> toJson() => {
    'aspect': aspect,
    'blocks': [for (final b in blocks) b.toJson()],
  };
}
