import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/l10n/app_language.dart';
import 'package:yoru/core/l10n/rebuild_all.dart';

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) => Text(AppText.t.home);
}

void main() {
  tearDown(() => AppText.language = AppLanguage.english);

  testWidgets('const widgets show a new language after rebuildAll', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(textDirection: TextDirection.ltr, child: _Home()),
    );
    expect(find.text('Home'), findsOneWidget);

    AppText.language = AppLanguage.indonesian;
    await tester.pump();
    // Nothing asked the const widget to build again.
    expect(find.text('Home'), findsOneWidget);

    rebuildAll(tester.binding.rootElement!);
    await tester.pump();
    expect(find.text('Beranda'), findsOneWidget);
  });
}
