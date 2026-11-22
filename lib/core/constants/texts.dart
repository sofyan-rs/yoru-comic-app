import 'dart:ui' show Locale;

import 'package:yoru/core/l10n/app_language.dart';
import 'package:yoru/l10n/app_localizations.dart';

export 'package:yoru/l10n/app_localizations.dart' show AppLocalizations;

/// The app's own text, in [language]: `AppText.t.home`. The messages live
/// in `lib/l10n/app_<code>.arb` (English is the template); `flutter
/// gen-l10n` makes [AppLocalizations] from them. Read without a
/// `BuildContext`, so blocs, notifications and background work can use it.
abstract final class AppText {
  static AppLanguage _language = AppLanguage.english;
  static AppLocalizations _t = _lookup(_language);

  /// Set from the settings before the first frame and whenever the user
  /// picks another language (see `SettingsCubit.changeLanguage`).
  static AppLanguage get language => _language;
  static set language(AppLanguage value) {
    _language = value;
    _t = _lookup(value);
  }

  /// The messages in [language].
  static AppLocalizations get t => _t;

  static AppLocalizations _lookup(AppLanguage language) =>
      lookupAppLocalizations(Locale(language.code));

  /// "Chapter 12", or the chapter's own [title] when its number was made
  /// up (see `Chapter.title`).
  static String chapterName(String number, [String? title]) =>
      title ?? _t.chapterNumber(number);
}
