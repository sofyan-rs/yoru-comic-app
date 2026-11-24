// Reads a page with the on-device OCR and prints what it found:
//
//   flutter test integration_test/ocr_smoke_test.dart -d windows \
//     --dart-define=OCR_PAGE=<path to a page image> --dart-define=OCR_SCRIPT=cjk
//
// Downloads the models on first run. Skipped without OCR_PAGE.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yoru/features/translate/data/ocr/ocr_models.dart';
import 'package:yoru/features/translate/data/ocr/paddle_ocr.dart';
import 'package:yoru/features/translate/data/ocr/text_grouping.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';

const _page = String.fromEnvironment('OCR_PAGE');
const _script = String.fromEnvironment('OCR_SCRIPT', defaultValue: 'cjk');
// The page shown above OCR_PAGE, read on top of it (the vertical reader).
const _above = String.fromEnvironment('OCR_ABOVE');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reads the text of a page', (tester) async {
    await tester.runAsync(() async {
      final ocr = PaddleOcr(OcrModels(Dio()));
      // A file, or a folder whose images are read one after another.
      final pages = FileSystemEntity.isDirectorySync(_page)
          ? (Directory(_page).listSync().whereType<File>().toList()
              ..sort((a, b) => a.path.compareTo(b.path)))
          : [File(_page)];
      var lines = <OcrLine>[];
      for (final file in pages) {
        final watch = Stopwatch()..start();
        final page = await ocr.read(
          await file.readAsBytes(),
          OcrScript.parse(_script),
          above: _above.isEmpty ? null : await File(_above).readAsBytes(),
        );
        lines = page.lines;
        // ignore: avoid_print
        print(
          'OCR ${file.path.split(RegExp(r'[\/]')).last} '
          '${page.width}x${page.height}: ${lines.length} lines in '
          '${watch.elapsedMilliseconds} ms',
        );
        for (final l in lines) {
          // ignore: avoid_print
          print(
            '  line ${l.text} (score ${l.score.toStringAsFixed(2)}, '
            '${l.rect.width.round()}x${l.rect.height.round()}${l.dark ? ' dark' : ''} '
            'at ${l.rect.left.round()},${l.rect.top.round()})',
          );
        }
        for (final b in groupLines(lines)) {
          // ignore: avoid_print
          print('BLOCK ${b.text}${b.dark ? ' (dark)' : ''}');
        }
      }
      expect(lines, isNotEmpty);
    });
  }, skip: _page.isEmpty);
}
