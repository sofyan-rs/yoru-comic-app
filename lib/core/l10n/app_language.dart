/// Language of the app's own text (not of the sources' comics). Plain Dart
/// so the domain layer can store it.
enum AppLanguage {
  english('en', 'English'),
  indonesian('id', 'Bahasa Indonesia');

  const AppLanguage(this.code, this.nativeName);

  /// Language code for `Locale`.
  final String code;

  /// Name in the language itself, as the picker lists it.
  final String nativeName;
}
