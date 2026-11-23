import 'dart:math';

/// Share of a slice the next one covers again.
const _overlap = 0.2;

/// Where each slice of a page [height] tall starts, slices [sliceHeight]
/// tall overlapping by [_overlap] (so a line on a cut is whole in one of
/// them); one slice when the page is little more than one.
List<int> sliceStarts(int height, int sliceHeight) {
  if (height <= sliceHeight * 1.15) return const [0];
  final step = (sliceHeight * (1 - _overlap)).round();
  final starts = <int>[];
  for (var y = 0; ; y += step) {
    if (y + sliceHeight >= height) {
      starts.add(max(0, height - sliceHeight));
      return starts;
    }
    starts.add(y);
  }
}
