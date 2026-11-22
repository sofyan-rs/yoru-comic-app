import 'package:flutter_test/flutter_test.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/l10n/app_language.dart';

void main() {
  tearDown(() => AppText.language = AppLanguage.english);

  test('English is the default', () {
    expect(AppText.language, AppLanguage.english);
    expect(AppText.t.home, 'Home');
  });

  test('switching the language switches the text', () {
    AppText.language = AppLanguage.indonesian;
    expect(AppText.t.home, 'Beranda');
    expect(AppText.chapterName('12'), 'Chapter 12');
    AppText.language = AppLanguage.english;
    expect(AppText.t.home, 'Home');
  });

  test('counts follow each language', () {
    expect(AppText.t.comicCount(1), '1 comic');
    expect(AppText.t.comicCount(3), '3 comics');
    expect(AppText.t.daysAgo(1), '1 day ago');
    AppText.language = AppLanguage.indonesian;
    expect(AppText.t.comicCount(1), '1 komik');
    expect(AppText.t.comicCount(3), '3 komik');
    expect(AppText.t.imported(2, 1), '2 chapter diimpor ke 1 seri');
  });

  test('every language has twelve months', () {
    for (final language in AppLanguage.values) {
      AppText.language = language;
      expect(AppText.t.monthsShort.split(','), hasLength(12));
    }
  });

  test('every AppLanguage has its messages', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      containsAll(AppLanguage.values.map((l) => l.code)),
    );
  });
}
