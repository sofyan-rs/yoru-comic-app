import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show Rect;

/// Text boxes from a DB (differentiable binarization) probability map, as
/// PaddleOCR's `DBPostProcess` finds them: pixels over [threshold] joined
/// into regions, regions whose mean probability is under [boxThreshold]
/// dropped, the rest expanded by [unclipRatio] (the model draws text
/// shrunk). Boxes are axis-aligned, in the map's pixels: comic lettering
/// is upright, so the rotated rectangles PaddleOCR fits are not needed.
List<Rect> dbBoxes(
  Float32List probability,
  int width,
  int height, {
  double threshold = 0.3,
  double boxThreshold = 0.6,
  double unclipRatio = 1.5,
  int maxCandidates = 1000,
  double minSide = 3,
}) {
  assert(probability.length == width * height);
  final seen = Uint8List(width * height);
  final stack = Int32List(width * height);
  final boxes = <Rect>[];

  for (var start = 0; start < probability.length; start++) {
    if (seen[start] != 0 || probability[start] <= threshold) continue;
    // Flood fill one region (4-connected).
    var top = 0;
    stack[top++] = start;
    seen[start] = 1;
    var minX = width, minY = height, maxX = -1, maxY = -1;
    var sum = 0.0;
    var count = 0;
    while (top > 0) {
      final i = stack[--top];
      final x = i % width;
      final y = i ~/ width;
      sum += probability[i];
      count++;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
      void visit(int j) {
        if (seen[j] == 0 && probability[j] > threshold) {
          seen[j] = 1;
          stack[top++] = j;
        }
      }

      if (x > 0) visit(i - 1);
      if (x < width - 1) visit(i + 1);
      if (y > 0) visit(i - width);
      if (y < height - 1) visit(i + width);
    }

    final w = (maxX - minX + 1).toDouble();
    final h = (maxY - minY + 1).toDouble();
    if (min(w, h) < minSide) continue;
    if (sum / count < boxThreshold) continue;
    // Polygon offset of a rectangle by area × ratio / perimeter.
    final d = w * h * unclipRatio / (2 * (w + h));
    final box = Rect.fromLTWH(minX.toDouble(), minY.toDouble(), w, h)
        .inflate(d)
        .intersect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
    if (min(box.width, box.height) < minSide + 2) continue;
    boxes.add(box);
    if (boxes.length >= maxCandidates) break;
  }
  return boxes;
}
