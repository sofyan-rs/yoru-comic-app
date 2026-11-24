import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:injectable/injectable.dart';
import 'package:yoru/features/translate/data/ocr/ocr_models.dart';
import 'package:yoru/features/translate/data/ocr/ocr_worker.dart';
import 'package:yoru/features/translate/data/ocr/text_grouping.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';

/// A page read: the size it was read at (its lines' boxes are in these
/// pixels) and its lines.
typedef OcrPage = ({int width, int height, List<OcrLine> lines});

/// Reads the text lines of a page with PaddleOCR v5 on ONNX Runtime, on
/// every platform: a detection model finds the lines, a recognition model
/// ([OcrScript]) reads each.
abstract interface class PageOcr {
  /// Lines of the page whose file is [bytes].
  Future<OcrPage> read(Uint8List bytes, OcrScript script);
}

/// Hands the page's file to an [OcrWorker], which does everything off the
/// UI thread. A file it cannot decode (AVIF) is decoded here and sent as
/// pixels.
@LazySingleton(as: PageOcr)
class PaddleOcr implements PageOcr {
  PaddleOcr(this._models);

  final OcrModels _models;
  final _worker = OcrWorker();

  /// Widest a page is decoded here, for the few the worker cannot read.
  static const _maxWidth = 1200;

  @override
  Future<OcrPage> read(Uint8List bytes, OcrScript script) async {
    final files = await _models.ensure(script);
    OcrPageResult page;
    try {
      page = await _worker.read((
        data: TransferableTypedData.fromList([bytes]),
        encoded: true,
        width: 0,
        height: 0,
        detection: files.detection,
        recognition: files.recognition,
        dictionary: files.dictionary,
        detectSide: script.detectSide,
      ));
    } on UndecodablePage {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: await _decodeWidth(bytes),
      );
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      try {
        final pixels = await image.toByteData();
        if (pixels == null) throw StateError('Could not read the page');
        page = await _worker.read((
          data: TransferableTypedData.fromList([pixels.buffer.asUint8List()]),
          encoded: false,
          width: image.width,
          height: image.height,
          detection: files.detection,
          recognition: files.recognition,
          dictionary: files.dictionary,
          detectSide: script.detectSide,
        ));
      } finally {
        image.dispose();
      }
    }
    return (
      width: page.width,
      height: page.height,
      lines: [
        for (final l in page.lines)
          OcrLine(
            rect: ui.Rect.fromLTRB(l.left, l.top, l.right, l.bottom),
            text: l.text,
            score: l.score,
            dark: l.dark,
          ),
      ],
    );
  }

  static Future<int> _decodeWidth(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final width = min(descriptor.width, _maxWidth);
    descriptor.dispose();
    buffer.dispose();
    return width;
  }
}
