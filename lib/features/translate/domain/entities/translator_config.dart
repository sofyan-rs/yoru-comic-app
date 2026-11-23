import 'package:yoru/features/settings/domain/entities/app_settings.dart';

/// Writing the pages are in, which picks the OCR model.
enum OcrScript {
  /// Japanese (also vertical), Chinese and English.
  cjk,
  korean,

  /// English: its own model reads comic lettering better than [latin]'s.
  english,

  /// Other languages in Latin letters, with their accents.
  latin;

  /// How big the detector sees a page (its long side): bigger for Latin
  /// letters, whose small lettering it otherwise misses or cuts (names
  /// misread); Japanese and Chinese read as well at less, faster.
  int get detectSide => this == cjk ? 960 : 1600;

  /// The setting's value as a script; unknown values (and `auto`) are
  /// [cjk].
  static OcrScript parse(String value) =>
      values.firstWhere((s) => s.name == value, orElse: () => cjk);

  /// The script a comic in [language] (an ISO 639-1 code, as sources give
  /// it) is written in: [cjk] for Japanese and Chinese, and when not known
  /// (`all`, a multi-language source); [english] for English; [latin] for
  /// the rest.
  static OcrScript forLanguage(String? language) {
    final code = (language ?? '').toLowerCase();
    if (code.isEmpty || code == 'all') return cjk;
    if (code.startsWith('ja') || code.startsWith('zh')) return cjk;
    if (code.startsWith('ko')) return korean;
    if (code.startsWith('en')) return english;
    return latin;
  }
}

/// How pages are translated: the app reads the text ([script]), an
/// OpenAI-compatible chat API translates it.
class TranslatorConfig {
  const TranslatorConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.language,
    this.script = OcrScript.cjk,
    this.notes = '',
    this.comic = '',
    this.autoScript = false,
    this.mlKit = false,
    this.sourceLanguage = '',
  });

  /// The config to translate with, or null when the server or model is
  /// missing.
  static TranslatorConfig? configured(AppSettings s) {
    final config = TranslatorConfig.fromSettings(s);
    return config.isReady ? config : null;
  }

  /// From the settings; an empty language means the app's language.
  factory TranslatorConfig.fromSettings(AppSettings s) => TranslatorConfig(
    baseUrl: normalizeBaseUrl(s.translateBaseUrl),
    apiKey: s.translateApiKey.trim(),
    model: s.translateModel.trim(),
    language: s.translateLanguage.trim().isNotEmpty
        ? s.translateLanguage.trim()
        : switch (s.language) {
            AppLanguage.english => 'English',
            AppLanguage.indonesian => 'Indonesian',
          },
    script: OcrScript.parse(s.translateScript),
    autoScript: s.translateScript == 'auto',
    mlKit: s.translateEngine == 'mlkit',
    notes: s.translateNotes.trim(),
  );

  /// This config for pages of the comic titled [title], from a source in
  /// [sourceLanguage]: with [autoScript], read as that language is written.
  TranslatorConfig forComic(String title, {String? sourceLanguage}) =>
      TranslatorConfig(
        baseUrl: baseUrl,
        apiKey: apiKey,
        model: model,
        language: language,
        script: autoScript ? OcrScript.forLanguage(sourceLanguage) : script,
        notes: notes,
        comic: title,
        mlKit: mlKit,
        sourceLanguage: sourceLanguage ?? '',
      );

  /// API root without a trailing slash, e.g. `https://api.openai.com/v1`.
  final String baseUrl;

  /// Empty for servers without a key (Ollama, LM Studio).
  final String apiKey;
  final String model;

  /// Target language, in English.
  final String language;

  /// Writing of the pages.
  final OcrScript script;

  /// [script] is picked by the comic's language ([forComic]).
  final bool autoScript;

  /// Translated by Google's ML Kit, on the device, without an AI model.
  final bool mlKit;

  /// The comic's language as its source gives it (`ja`, `en`…); empty when
  /// not known. ML Kit translates from it.
  final String sourceLanguage;

  /// The user's own instructions for the translations.
  final String notes;

  /// Title of the comic, for context; empty when not known.
  final String comic;

  /// Enough is set to make a request: ML Kit, or a server and its
  /// model.
  bool get isReady => mlKit || (baseUrl.isNotEmpty && model.isNotEmpty);

  /// Part of the cache key: a page translated by another model, into
  /// another language or with other notes is translated again.
  String get cacheTag => mlKit
      ? 'mlkit:$sourceLanguage|$language|${script.name}'
      : '$baseUrl|$model|$language|${script.name}|$notes';

  @override
  bool operator ==(Object other) =>
      other is TranslatorConfig &&
      other.baseUrl == baseUrl &&
      other.apiKey == apiKey &&
      other.model == model &&
      other.language == language &&
      other.script == script &&
      other.autoScript == autoScript &&
      other.mlKit == mlKit &&
      other.sourceLanguage == sourceLanguage &&
      other.notes == notes &&
      other.comic == comic;

  @override
  int get hashCode => Object.hash(
    baseUrl,
    apiKey,
    model,
    language,
    script,
    notes,
    comic,
    mlKit,
    sourceLanguage,
  );

  /// Trims, drops trailing slashes and a pasted `/chat/completions`, and
  /// adds `https://` when no scheme is given.
  static String normalizeBaseUrl(String url) {
    var u = url.trim();
    if (u.isEmpty) return '';
    if (!u.contains('://')) u = 'https://$u';
    u = u.replaceAll(RegExp(r'/+$'), '');
    const suffix = '/chat/completions';
    if (u.endsWith(suffix)) u = u.substring(0, u.length - suffix.length);
    return u;
  }
}
