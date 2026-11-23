import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:injectable/injectable.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';

/// Google's ML Kit translation, on Android and iOS: offline once its
/// language packs (about 30 MB each) are downloaded, which happens the
/// first time a language is needed. No AI model: plainer than one, and it
/// cannot fix OCR mistakes or follow notes.
@lazySingleton
class MlKitTranslation {
  final _models = OnDeviceTranslatorModelManager();
  final _translators = <String, OnDeviceTranslator>{};

  /// [texts] translated from the comic's language into [config]'s.
  Future<List<String>> translate(
    List<String> texts, {
    required TranslatorConfig config,
  }) async {
    final source = mlKitSource(config.sourceLanguage, config.script);
    final target = mlKitTarget(config.language);
    if (target == null) {
      throw StateError('ML Kit cannot translate into ${config.language}');
    }
    if (source == target) return texts;
    for (final language in {source, target}) {
      if (!await _models.isModelDownloaded(language.bcpCode)) {
        final ok = await _models.downloadModel(
          language.bcpCode,
          isWifiRequired: false,
        );
        if (!ok) {
          throw StateError('Could not download the ${language.name} pack');
        }
      }
    }
    final translator = _translators['${source.bcpCode}>${target.bcpCode}'] ??=
        OnDeviceTranslator(sourceLanguage: source, targetLanguage: target);
    return [
      for (final text in texts) (await translator.translateText(text)).trim(),
    ];
  }
}

/// The language a comic is in, from its source's code (`ja`, `en`…), or
/// guessed from how its pages are written when the source does not say.
TranslateLanguage mlKitSource(String code, OcrScript script) {
  final base = code.toLowerCase().split(RegExp('[-_]')).first;
  final known = BCP47Code.fromRawValue(base);
  if (known != null) return known;
  return switch (script) {
    OcrScript.cjk => TranslateLanguage.japanese,
    OcrScript.korean => TranslateLanguage.korean,
    OcrScript.english || OcrScript.latin => TranslateLanguage.english,
  };
}

/// The language to translate into, from its English name ("Indonesian",
/// "Chinese (Simplified)"), or null when ML Kit has no such language.
TranslateLanguage? mlKitTarget(String name) {
  final key = name.toLowerCase().split(RegExp(r'[\s(]')).first;
  for (final language in TranslateLanguage.values) {
    if (language.name == key) return language;
  }
  return null;
}
