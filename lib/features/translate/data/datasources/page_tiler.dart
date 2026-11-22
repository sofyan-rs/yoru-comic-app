import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Side of the square image every tile is sent as. Some models answer
/// boxes in 0–1000, others in pixels; on a 1000 px square both are the
/// same numbers.
const modelCanvas = 1000;

/// A slice of a page sent to the model on its own: drawn at the top left
/// of a white [modelCanvas] square, as large as fits.
class PageTile {
  const PageTile({
    required this.png,
    required this.contentWidth,
    required this.contentHeight,
    required this.top,
    required this.bottom,
    required this.ownTop,
    required this.ownBottom,
  });

  final Uint8List png;

  /// How much of the square the slice covers, as fractions of its side.
  final double contentWidth;
  final double contentHeight;

  /// Where the tile sits on the page, in fractions of its height.
  final double top;
  final double bottom;

  /// The part of the page this tile answers for. Tiles overlap so a bubble
  /// on a cut is whole in one of them; a block found in the overlap is kept
  /// only by the tile that owns its centre.
  final double ownTop;
  final double ownBottom;
}

/// A page made ready for the model.
class TiledPage {
  const TiledPage({required this.aspect, required this.tiles});

  /// Height over width of the page.
  final double aspect;
  final List<PageTile> tiles;
}

/// Tallest a decoded page may be, so a very long strip does not take
/// hundreds of MB while it is cut.
const _maxDecodedHeight = 16000;

/// Tallest tile, over its width. Models shrink a tall image to fit, which
/// makes the lettering of a long webtoon strip unreadable.
const _maxTileAspect = 1.5;

/// Share of a tile that the next one covers again.
const _overlap = 0.2;

/// Decodes [bytes] (any format the engine decodes) at most [modelCanvas]
/// wide, cuts a tall page into overlapping tiles and draws each on a
/// [modelCanvas] square.
Future<TiledPage> tilePage(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final aspect = descriptor.height / descriptor.width;
  final width = [
    descriptor.width,
    modelCanvas,
    (_maxDecodedHeight / aspect).floor(),
  ].reduce(min).clamp(1, modelCanvas);
  final codec = await descriptor.instantiateCodec(targetWidth: width);
  final image = (await codec.getNextFrame()).image;
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();

  try {
    final w = image.width;
    final h = image.height;
    final tileHeight = (w * _maxTileAspect).round();
    // A little over a tile is not worth a second request.
    if (h <= tileHeight * 1.15) {
      return TiledPage(
        aspect: aspect,
        tiles: [await _tile(image, 0, h, ownTop: 0, ownBottom: h.toDouble())],
      );
    }

    final step = (tileHeight * (1 - _overlap)).round();
    final starts = <int>[];
    for (var y = 0; ; y += step) {
      if (y + tileHeight >= h) {
        starts.add(max(0, h - tileHeight));
        break;
      }
      starts.add(y);
    }

    final tiles = <PageTile>[];
    for (final (i, start) in starts.indexed) {
      final end = min(h, start + tileHeight);
      // Owned range: up to the middle of each overlap.
      final ownTop = i == 0 ? 0.0 : (start + starts[i - 1] + tileHeight) / 2;
      final ownBottom = i == starts.length - 1
          ? h.toDouble()
          : (end + starts[i + 1]) / 2;
      tiles.add(
        await _tile(image, start, end, ownTop: ownTop, ownBottom: ownBottom),
      );
    }
    return TiledPage(aspect: aspect, tiles: tiles);
  } finally {
    image.dispose();
  }
}

/// Rows [start] to [end] of [image] on a white [modelCanvas] square.
Future<PageTile> _tile(
  ui.Image image,
  int start,
  int end, {
  required double ownTop,
  required double ownBottom,
}) async {
  final w = image.width.toDouble();
  final h = (end - start).toDouble();
  final scale = modelCanvas / max(w, h);
  const side = modelCanvas * 1.0;
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder)
    ..drawRect(
      const ui.Rect.fromLTWH(0, 0, side, side),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    )
    ..drawImageRect(
      image,
      ui.Rect.fromLTWH(0, start.toDouble(), w, h),
      ui.Rect.fromLTWH(0, 0, w * scale, h * scale),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
  final picture = recorder.endRecording();
  final square = await picture.toImage(modelCanvas, modelCanvas);
  picture.dispose();
  try {
    final data = await square.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('Could not encode the page');
    final pageHeight = image.height;
    return PageTile(
      png: data.buffer.asUint8List(),
      contentWidth: w * scale / side,
      contentHeight: h * scale / side,
      top: start / pageHeight,
      bottom: end / pageHeight,
      ownTop: ownTop / pageHeight,
      ownBottom: ownBottom / pageHeight,
    );
  } finally {
    square.dispose();
  }
}
