import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yoru/core/di/register_module.dart';
import 'package:yoru/features/translate/data/ocr/onnx_patch.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';

/// PaddleOCR v5 mobile models in ONNX (Apache-2.0), as RapidOCR publishes
/// them. Downloaded on first use into `<app support>/ocr/`.
const _modelsBase =
    'https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/v3.10.0';

/// Finds the text lines on a page, any script.
const _detection = 'onnx/PP-OCRv5/det/ch_PP-OCRv5_det_mobile.onnx';

/// Reads lines: the model and its character list, per [OcrScript].
const _recognition = <OcrScript, (String, String)>{
  // Chinese, Japanese (also vertical) and English in one model.
  OcrScript.cjk: (
    'onnx/PP-OCRv5/rec/ch_PP-OCRv5_rec_mobile.onnx',
    'paddle/PP-OCRv5/rec/ch_PP-OCRv5_rec_mobile/ppocrv5_dict.txt',
  ),
  OcrScript.korean: (
    'onnx/PP-OCRv5/rec/korean_PP-OCRv5_rec_mobile.onnx',
    'paddle/PP-OCRv5/rec/korean_PP-OCRv5_rec_mobile/ppocrv5_korean_dict.txt',
  ),
  OcrScript.english: (
    'onnx/PP-OCRv5/rec/en_PP-OCRv5_rec_mobile.onnx',
    'paddle/PP-OCRv5/rec/en_PP-OCRv5_rec_mobile/ppocrv5_en_dict.txt',
  ),
  OcrScript.latin: (
    'onnx/PP-OCRv5/rec/latin_PP-OCRv5_rec_mobile.onnx',
    'paddle/PP-OCRv5/rec/latin_PP-OCRv5_rec_mobile/ppocrv5_latin_dict.txt',
  ),
};

/// Local files of the models for one script: the detector, the recognizer
/// (patched by [withBestClass]) and its character list, one per line.
typedef OcrModelFiles = ({
  String detection,
  String recognition,
  String dictionary,
});

/// The OCR models on this device: downloads them when first needed.
@lazySingleton
class OcrModels {
  OcrModels(@Named(filesDio) this._dio);

  final Dio _dio;

  late final Future<Directory> _dir = () async {
    final dir = Directory(
      '${(await getApplicationSupportDirectory()).path}/ocr',
    );
    await dir.create(recursive: true);
    return dir;
  }();

  final _ready = <OcrScript, Future<OcrModelFiles>>{};

  /// The models for [script], downloading what is missing. Concurrent
  /// calls share one download; a failed one is tried again next time.
  Future<OcrModelFiles> ensure(OcrScript script) {
    final ready = _ready[script] ??= _ensure(script);
    ready.then(
      (_) {},
      onError: (Object _) {
        _ready.remove(script);
      },
    );
    return ready;
  }

  /// Whether the models for [script] are on the device already.
  Future<bool> has(OcrScript script) async {
    final dir = (await _dir).path;
    final (rec, dict) = _recognition[script]!;
    for (final path in [_detection, rec, dict]) {
      if (!await File('$dir/${path.split('/').last}').exists()) return false;
    }
    return true;
  }

  Future<OcrModelFiles> _ensure(OcrScript script) async {
    final (rec, dict) = _recognition[script]!;
    final files = await Future.wait([
      _file(_detection),
      _file(rec),
      _file(dict),
    ]);
    return (
      detection: files[0],
      recognition: await _withBestClass(files[1]),
      dictionary: files[2],
    );
  }

  /// [model] patched by [withBestClass], made once beside it.
  Future<String> _withBestClass(String model) async {
    final patched = File(model.replaceFirst(RegExp(r'\.onnx$'), '.best.onnx'));
    if (await patched.exists() && await patched.length() > 0) {
      return patched.path;
    }
    final part = File('${patched.path}.part');
    await Isolate.run(() async {
      final bytes = await File(model).readAsBytes();
      await part.writeAsBytes(withBestClass(bytes), flush: true);
    });
    await part.rename(patched.path);
    return patched.path;
  }

  /// [path] on the server as a local file, downloaded once (to a temporary
  /// name first, so a cut download is never taken for a model).
  Future<String> _file(String path) async {
    final local = File('${(await _dir).path}/${path.split('/').last}');
    if (await local.exists() && await local.length() > 0) return local.path;
    final part = File('${local.path}.part');
    debugPrint('OCR: downloading $path');
    await _dio.download(
      '$_modelsBase/$path',
      part.path,
      options: Options(receiveTimeout: const Duration(minutes: 5)),
    );
    await part.rename(local.path);
    return local.path;
  }

  /// Bytes the downloaded models take.
  Future<int> size() async {
    var total = 0;
    await for (final f in (await _dir).list()) {
      if (f is File) total += await f.length();
    }
    return total;
  }

  /// Removes every downloaded model.
  Future<void> delete() async {
    _ready.clear();
    final dir = await _dir;
    await for (final f in dir.list()) {
      await f.delete(recursive: true);
    }
  }
}
