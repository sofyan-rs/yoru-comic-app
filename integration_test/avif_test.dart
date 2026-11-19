import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yoru/core/utils/image_support.dart';

/// Converts an AVIF to PNG with the bundled libavif, as the image caches do
/// on a device without an AVIF decoder. Run on a desktop with
/// `flutter test integration_test/avif_test.dart -d windows
/// --dart-define=AVIF_FILE=path/to/cover.avif`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AVIF converts to a PNG Flutter decodes', (tester) async {
    const path = String.fromEnvironment('AVIF_FILE');
    if (path.isEmpty) {
      markTestSkipped('No AVIF_FILE given');
      return;
    }
    await tester.runAsync(() async {
      final avif = await File(path).readAsBytes();
      expect(isAvif(avif), isTrue);
      final png = await avifToPng(avif);
      expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      debugPrint(
        'AVIF ${await avifSupported() ? 'decodes' : 'does not decode'} natively; '
        'PNG ${frame.image.width}x${frame.image.height}, ${png.length} bytes',
      );
      expect(frame.image.width, greaterThan(1));
      frame.image.dispose();
      codec.dispose();
    });
  });
}
