import 'package:yoru/features/settings/domain/entities/app_settings.dart';

/// Where and how pages are translated: an OpenAI-compatible chat API with a
/// model that reads images.
class TranslatorConfig {
  const TranslatorConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.language,
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
  );

  /// API root without a trailing slash, e.g. `https://api.openai.com/v1`.
  final String baseUrl;

  /// Empty for servers without a key (Ollama, LM Studio).
  final String apiKey;
  final String model;

  /// Target language, in English.
  final String language;

  /// Enough is set to make a request.
  bool get isReady => baseUrl.isNotEmpty && model.isNotEmpty;

  /// Part of the cache key: a page translated by another model or into
  /// another language is translated again.
  String get cacheTag => '$baseUrl|$model|$language';

  @override
  bool operator ==(Object other) =>
      other is TranslatorConfig &&
      other.baseUrl == baseUrl &&
      other.apiKey == apiKey &&
      other.model == model &&
      other.language == language;

  @override
  int get hashCode => Object.hash(baseUrl, apiKey, model, language);

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
