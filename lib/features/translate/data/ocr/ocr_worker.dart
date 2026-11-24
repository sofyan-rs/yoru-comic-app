import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;
import 'package:yoru/features/translate/data/ocr/ctc_decode.dart';
import 'package:yoru/features/translate/data/ocr/db_postprocess.dart';
import 'package:yoru/features/translate/data/ocr/onnx_patch.dart';
import 'package:yoru/features/translate/data/ocr/page_slices.dart';
import 'package:yoru/features/translate/data/ocr/text_grouping.dart';

/// A line read: its box in the page's pixels, text and confidence.
typedef OcrResult = ({
  double left,
  double top,
  double right,
  double bottom,
  String text,
  double score,

  /// On a dark background (white lettering on black, say).
  bool dark,
});

/// A page read: the size it was read at, and its lines.
typedef OcrPageResult = ({int width, int height, List<OcrResult> lines});

/// What the worker reads: a page as its file's bytes ([encoded]), or as
/// RGBA pixels [width] × [height]; and the model files.
typedef OcrRequest = ({
  TransferableTypedData data,

  /// The file of the page shown above this one, whose bottom is read on
  /// top of it; null for none.
  TransferableTypedData? above,
  bool encoded,
  int width,
  int height,
  String detection,
  String recognition,
  String dictionary,

  /// Long side the detector sees ([OcrScript.detectSide]).
  int detectSide,
});

/// The worker could not decode a page's file (AVIF, say): the caller
/// decodes it and sends the pixels.
class UndecodablePage implements Exception {
  const UndecodablePage();
}

/// Runs OCR on a background isolate, so the reader keeps scrolling:
/// decoding the page, the image work (slicing a long strip, scaling,
/// cropping, turning lines), the models (ONNX Runtime through its plugin,
/// reached with [BackgroundIsolateBinaryMessenger]) and the decoding of
/// their output. The UI isolate only hands over the file.
class OcrWorker {
  Future<SendPort>? _port;
  final _replies = <int, Completer<OcrPageResult>>{};
  var _next = 0;

  Future<SendPort> _start() async {
    final token = RootIsolateToken.instance!;
    final fromWorker = ReceivePort();
    final ready = Completer<SendPort>();
    fromWorker.listen((message) {
      switch (message) {
        case final SendPort port:
          ready.complete(port);
        case (final int id, final OcrPageResult page):
          _replies.remove(id)?.complete(page);
        case (final int id, null):
          _replies.remove(id)?.completeError(const UndecodablePage());
        case (final int id, final String error):
          _replies.remove(id)?.completeError(StateError(error));
      }
    });
    await Isolate.spawn(_main, (fromWorker.sendPort, token), debugName: 'ocr');
    return ready.future;
  }

  Future<OcrPageResult> read(OcrRequest request) async {
    final port = await (_port ??= _start());
    final id = _next++;
    final reply = _replies[id] = Completer<OcrPageResult>();
    port.send((id, request));
    return reply.future;
  }
}

void _main((SendPort, RootIsolateToken) args) {
  final (toMain, token) = args;
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  final engine = _Engine();
  final requests = ReceivePort();
  toMain.send(requests.sendPort);
  // One page at a time.
  var turn = Future<void>.value();
  requests.listen((message) {
    final (id, request) = message as (int, OcrRequest);
    turn = turn.then((_) async {
      try {
        toMain.send((id, await engine.read(request)));
      } on UndecodablePage {
        toMain.send((id, null));
      } catch (e) {
        toMain.send((id, e.toString()));
      }
    });
  });
}

class _Engine {
  final _runtime = OnnxRuntime();
  final _sessions = <String, Future<OrtSession>>{};
  final _dictionaries = <String, Future<List<String>>>{};

  /// Share of a line's height added around it before it is read: the
  /// detector's boxes can cut the first or last letter (an R read as S).
  static const _margin = 0.08;

  /// Tallest slice the detector sees at once, over its width: a long strip
  /// shrunk whole would make its lettering too small to find.
  static const _maxSliceAspect = 1.6;

  /// Height the recognizer reads lines at.
  static const _lineHeight = 48;

  /// Widest line, so a long caption stays within memory.
  static const _maxLineWidth = 1600;

  /// Height of the strip of the page above read with a page, over its
  /// width: room for a balloon cut by the seam.
  static const _seamAspect = 0.5;

  /// Lines read per recognizer run.
  static const _batch = 8;

  /// A line read with less confidence is art, not text.
  static const _minScore = 0.5;

  /// Background luma (0-255) below which a line counts as on a dark
  /// background.
  static const _darkLuma = 100;

  Future<OrtSession> _session(String path) =>
      _sessions[path] ??= _runtime.createSession(path);

  Future<List<String>> _dictionary(String path) =>
      _dictionaries[path] ??= File(path).readAsLines().then(
        (lines) => [
          for (final l in lines)
            if (l.isNotEmpty) l,
        ],
      );

  Future<OcrPageResult> read(OcrRequest r) async {
    final data = r.data.materialize().asUint8List();
    _Rgba image;
    if (r.encoded) {
      final decoded = img.decodeImage(data);
      if (decoded == null) throw const UndecodablePage();
      image = _Rgba(
        decoded.getBytes(order: img.ChannelOrder.rgba),
        decoded.width,
        decoded.height,
      );
    } else {
      image = _Rgba(data, r.width, r.height);
    }
    // The bottom of the page above on top: lines cut by the seam are read
    // whole, then moved up by the strip's height (their tops above 0).
    var seam = 0;
    final aboveData = r.above;
    if (aboveData != null) {
      try {
        final above = img.decodeImage(aboveData.materialize().asUint8List());
        if (above != null) {
          final strip = min(above.height, (above.width * _seamAspect).round());
          var part = img.copyCrop(
            above,
            x: 0,
            y: above.height - strip,
            width: above.width,
            height: strip,
          );
          if (part.width != image.width) {
            part = img.copyResize(part, width: image.width);
          }
          final top = part.getBytes(order: img.ChannelOrder.rgba);
          final joined = Uint8List(top.length + image.pixels.length)
            ..setAll(0, top)
            ..setAll(top.length, image.pixels);
          seam = part.height;
          image = _Rgba(joined, image.width, image.height + seam);
        }
      } catch (_) {
        // The page above cannot be read here: this page alone.
      }
    }

    // The page in overlapping slices; a line is kept by the slice that
    // owns its centre.
    final detector = await _session(r.detection);
    final sliceHeight = (image.width * _maxSliceAspect).round();
    final starts = sliceStarts(image.height, sliceHeight);
    final boxes = <Rect>[];
    for (final (i, start) in starts.indexed) {
      final end = min(image.height, start + sliceHeight);
      final ownTop = i == 0 ? 0.0 : (start + starts[i - 1] + sliceHeight) / 2;
      final ownBottom = i == starts.length - 1
          ? image.height.toDouble()
          : (end + starts[i + 1]) / 2;
      final region = Rect.fromLTRB(
        0,
        start.toDouble(),
        image.width.toDouble(),
        end.toDouble(),
      );
      for (final box in await _detect(image, region, detector, r.detectSide)) {
        final centre = box.center.dy;
        if (centre >= ownTop && centre <= ownBottom) boxes.add(box);
      }
    }
    final read = boxes.isEmpty
        ? const <OcrResult>[]
        : await _recognize(
            image,
            boxes,
            await _session(r.recognition),
            await _dictionary(r.dictionary),
          );
    final lines = seam == 0
        ? read
        : [
            for (final l in read)
              (
                left: l.left,
                top: l.top - seam,
                right: l.right,
                bottom: l.bottom - seam,
                text: l.text,
                score: l.score,
                dark: l.dark,
              ),
          ];
    return (width: image.width, height: image.height - seam, lines: lines);
  }

  /// Boxes of the text lines in [region] of [image], in page pixels.
  Future<List<Rect>> _detect(
    _Rgba image,
    Rect region,
    OrtSession session,
    int detectSide,
  ) async {
    final scale = detectSide / max(region.width, region.height);
    int side(double v) => max(32, (v * scale / 32).round() * 32);
    final w = side(region.width);
    final h = side(region.height);
    final input = Float32List(3 * w * h);
    // As PP-OCRv5's detector was trained: BGR, the ImageNet mean and
    // deviation applied in that channel order.
    image.sample(
      input,
      offset: 0,
      width: w,
      height: h,
      rowStride: w,
      transform: _Affine.crop(region, w, h),
      mean: const [0.485, 0.456, 0.406],
      std: const [0.229, 0.224, 0.225],
    );
    final outputs = await _run(session, input, [1, 3, h, w]);
    final probability = _floats(await outputs.values.first.asFlattenedList());
    await _dispose(outputs);
    final sx = region.width / w;
    final sy = region.height / h;
    return [
      for (final b in dbBoxes(probability, w, h))
        Rect.fromLTRB(
          region.left + b.left * sx,
          region.top + b.top * sy,
          region.left + b.right * sx,
          region.top + b.bottom * sy,
        ),
    ];
  }

  Future<List<OcrResult>> _recognize(
    _Rgba image,
    List<Rect> boxes,
    OrtSession session,
    List<String> dictionary,
  ) async {
    // A little room around each line, more along it than across.
    boxes = [
      for (final b in boxes)
        isVerticalBox(b)
            ? Rect.fromLTRB(
                b.left - b.width * _margin / 2,
                b.top - b.width * _margin,
                b.right + b.width * _margin / 2,
                b.bottom + b.width * _margin,
              )
            : Rect.fromLTRB(
                b.left - b.height * _margin,
                b.top - b.height * _margin / 2,
                b.right + b.height * _margin,
                b.bottom + b.height * _margin / 2,
              ),
    ];
    // Similar widths together, so little of a batch is padding.
    final order = [for (var i = 0; i < boxes.length; i++) i]
      ..sort((a, b) => _lineWidth(boxes[a]).compareTo(_lineWidth(boxes[b])));
    final results = <OcrResult>[];
    for (var start = 0; start < order.length; start += _batch) {
      final batch = order.sublist(start, min(start + _batch, order.length));
      final width = batch.map((i) => _lineWidth(boxes[i])).reduce(max);
      final plane = _lineHeight * width;
      final input = Float32List(batch.length * 3 * plane);
      for (final (n, i) in batch.indexed) {
        final box = boxes[i];
        final w = _lineWidth(box);
        image.sample(
          input,
          offset: n * 3 * plane,
          width: w,
          height: _lineHeight,
          rowStride: width,
          transform: isVerticalBox(box)
              ? _Affine.turned(box, w, _lineHeight)
              : _Affine.crop(box, w, _lineHeight),
          mean: const [0.5, 0.5, 0.5],
          std: const [0.5, 0.5, 0.5],
        );
      }
      final outputs = await _run(session, input, [
        batch.length,
        3,
        _lineHeight,
        width,
      ]);
      final classes = outputs[bestClassOutput]!;
      final best = [
        for (final v in await classes.asFlattenedList()) (v as num).toInt(),
      ];
      final scores = _floats(await outputs[bestScoreOutput]!.asFlattenedList());
      final steps = classes.shape.last;
      await _dispose(outputs);
      for (final (n, i) in batch.indexed) {
        final read = ctcDecode(
          best,
          scores,
          offset: n * steps,
          steps: steps,
          dictionary: dictionary,
        );
        if (read.text.isEmpty || read.score < _minScore) continue;
        final b = boxes[i];
        results.add((
          left: b.left,
          top: b.top,
          right: b.right,
          bottom: b.bottom,
          text: read.text,
          score: read.score,
          dark: image.backgroundLuma(b) < _darkLuma,
        ));
      }
    }
    return results;
  }

  /// Width of [box] read as a line [_lineHeight] high (a vertical column
  /// turned a quarter first).
  int _lineWidth(Rect box) {
    final (w, h) = isVerticalBox(box)
        ? (box.height, box.width)
        : (box.width, box.height);
    return (w * _lineHeight / h).round().clamp(_lineHeight ~/ 2, _maxLineWidth);
  }

  Future<Map<String, OrtValue>> _run(
    OrtSession session,
    Float32List input,
    List<int> shape,
  ) async {
    final value = await OrtValue.fromList(input, shape);
    try {
      return await session.run({session.inputNames.first: value});
    } finally {
      await value.dispose();
    }
  }

  Future<void> _dispose(Map<String, OrtValue> outputs) async {
    for (final o in outputs.values) {
      await o.dispose();
    }
  }

  static Float32List _floats(List<dynamic> list) => list is Float32List
      ? list
      : Float32List.fromList([for (final v in list) (v as num).toDouble()]);
}

/// Where an output pixel (x, y) samples the source: `sx = a·x + b·y + c`,
/// `sy = d·x + e·y + f`, at pixel centres.
class _Affine {
  const _Affine(this.a, this.b, this.c, this.d, this.e, this.f);

  /// [box] scaled to [width] × [height].
  factory _Affine.crop(Rect box, int width, int height) {
    final kx = box.width / width;
    final ky = box.height / height;
    return _Affine(
      kx,
      0,
      box.left + 0.5 * kx - 0.5,
      0,
      ky,
      box.top + 0.5 * ky - 0.5,
    );
  }

  /// [box], a column, turned a quarter counter-clockwise into a [width] ×
  /// [height] line: its top at the line's left, its right side at the top.
  factory _Affine.turned(Rect box, int width, int height) {
    final kx = box.width / height;
    final ky = box.height / width;
    return _Affine(
      0,
      -kx,
      box.right - 0.5 * kx - 0.5,
      ky,
      0,
      box.top + 0.5 * ky - 0.5,
    );
  }

  final double a, b, c, d, e, f;
}

/// RGBA pixels, sampled bilinearly.
class _Rgba {
  _Rgba(this.pixels, this.width, this.height);

  final Uint8List pixels;
  final int width;
  final int height;

  /// The usual brightness (0-255) behind the letters in [box]: the median
  /// luma over a grid inside it. Letter strokes are thin, so most of a
  /// line's box is its balloon (white) or panel (dark); a ring outside it
  /// would land on the art around a small balloon instead.
  int backgroundLuma(Rect box) {
    final lumas = <int>[];
    const columns = 24;
    const rows = 8;
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final x = box.left + box.width * (column + 0.5) / columns;
        final y = box.top + box.height * (row + 0.5) / rows;
        final px = x.round().clamp(0, width - 1);
        final py = y.round().clamp(0, height - 1);
        final i = (py * width + px) * 4;
        lumas.add(
          (pixels[i] * 299 + pixels[i + 1] * 587 + pixels[i + 2] * 114) ~/ 1000,
        );
      }
    }
    lumas.sort();
    return lumas[lumas.length ~/ 2];
  }

  /// Writes a [width] × [height] image sampled through [transform] into
  /// [out] at [offset], as CHW planes in BGR order, normalized; rows
  /// [rowStride] wide (the rest of a padded row stays 0).
  void sample(
    Float32List out, {
    required int offset,
    required int width,
    required int height,
    required int rowStride,
    required _Affine transform,
    required List<double> mean,
    required List<double> std,
  }) {
    final plane = rowStride * height;
    final t = transform;
    final maxX = this.width - 1;
    final maxY = this.height - 1;
    final p = pixels;
    final w = this.width;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final sx = (t.a * x + t.b * y + t.c).clamp(0.0, maxX.toDouble());
        final sy = (t.d * x + t.e * y + t.f).clamp(0.0, maxY.toDouble());
        final x0 = sx.floor();
        final y0 = sy.floor();
        final x1 = min(x0 + 1, maxX);
        final y1 = min(y0 + 1, maxY);
        final fx = sx - x0;
        final fy = sy - y0;
        final i00 = (y0 * w + x0) * 4;
        final i10 = (y0 * w + x1) * 4;
        final i01 = (y1 * w + x0) * 4;
        final i11 = (y1 * w + x1) * 4;
        double at(int c) {
          final top = p[i00 + c] + (p[i10 + c] - p[i00 + c]) * fx;
          final bottom = p[i01 + c] + (p[i11 + c] - p[i01 + c]) * fx;
          return top + (bottom - top) * fy;
        }

        final o = offset + y * rowStride + x;
        out[o] = (at(2) / 255 - mean[0]) / std[0];
        out[o + plane] = (at(1) / 255 - mean[1]) / std[1];
        out[o + 2 * plane] = (at(0) / 255 - mean[2]) / std[2];
      }
    }
  }
}
