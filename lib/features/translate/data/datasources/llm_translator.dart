import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:yoru/core/di/register_module.dart';
import 'package:yoru/core/error/exceptions.dart';
import 'package:yoru/features/translate/data/device/mlkit_translation.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';

/// Translates the text read off a page through an OpenAI-compatible
/// `chat/completions` API (OpenAI, Gemini, OpenRouter, Claude, DeepSeek,
/// Ollama, LM Studio…). Any chat model does: it sees text, not the image.
abstract interface class LlmTranslator {
  /// [texts] (a page's balloons in reading order) translated, one for each
  /// and in the same order; empty for one that is no real text. [context]:
  /// the last translated lines of the page before.
  Future<List<String>> translate(
    List<String> texts, {
    required TranslatorConfig config,
    List<String> context = const [],
  });
}

@LazySingleton(as: LlmTranslator)
class LlmTranslatorImpl implements LlmTranslator {
  LlmTranslatorImpl(@Named(filesDio) this._dio, this._mlKit);

  final Dio _dio;
  final MlKitTranslation _mlKit;

  /// `<baseUrl>|<model>` pairs that answered 400 to [noThinking]'s fields.
  final _thinkingRefused = <String>{};

  /// Local models can take a while.
  static const _timeout = Duration(minutes: 3);

  Future<Response<dynamic>> _post(
    TranslatorConfig config,
    Map<String, Object> body,
  ) => _dio.post<dynamic>(
    '${config.baseUrl}/chat/completions',
    options: Options(
      headers: {
        if (config.apiKey.isNotEmpty)
          'Authorization': 'Bearer ${config.apiKey}',
      },
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      sendTimeout: _timeout,
      receiveTimeout: _timeout,
    ),
    data: body,
  );

  @override
  Future<List<String>> translate(
    List<String> texts, {
    required TranslatorConfig config,
    List<String> context = const [],
  }) async {
    if (texts.isEmpty) return const [];
    if (config.mlKit) {
      try {
        return await _mlKit.translate(texts, config: config);
      } on StateError catch (e) {
        throw ServerException(e.message);
      } on PlatformException catch (e) {
        throw ServerException('ML Kit: ${e.message}');
      }
    }
    final watch = Stopwatch()..start();
    final body = {
      'model': config.model,
      'temperature': 0.2,
      'messages': [
        {
          'role': 'system',
          'content': translatePrompt(
            config.language,
            comic: config.comic,
            notes: config.notes,
          ),
        },
        {'role': 'user', 'content': _userMessage(texts, context)},
      ],
    };
    final server = '${config.baseUrl}|${config.model}';
    final extra = _thinkingRefused.contains(server)
        ? const <String, Object>{}
        : noThinking(config.baseUrl);
    Response<dynamic> response;
    try {
      response = await _post(config, {...body, ...extra});
    } on DioException catch (e) {
      // A server or model that does not take the switch (one that cannot
      // think, or cannot stop): ask again without it, and from now on.
      if (extra.isEmpty || e.response?.statusCode != 400) {
        throw ServerException(_errorMessage(e));
      }
      _thinkingRefused.add(server);
      debugPrint('Translate: retrying without $extra: ${_errorMessage(e)}');
      try {
        response = await _post(config, body);
      } on DioException catch (e) {
        throw ServerException(_errorMessage(e));
      }
    }

    final data = response.data;
    debugPrint(
      'Translate: ${config.model} answered in ${watch.elapsedMilliseconds} ms '
      '(${texts.length} texts, usage '
      '${data is Map ? jsonEncode(data['usage']) : '?'})',
    );
    final content = _content(response.data);
    if (content == null) {
      throw const ServerException('The model sent no answer');
    }
    try {
      return parseTranslations(content, texts.length);
    } on FormatException catch (e) {
      debugPrint('Translate: unreadable answer: $content');
      throw ServerException('Unreadable answer from the model: ${e.message}');
    }
  }

  /// `choices[0].message.content`, as a string or a list of text parts.
  static String? _content(dynamic data) {
    final body = data is String ? jsonDecode(data) : data;
    if (body is! Map) return null;
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final content = (choices.first as Map)['message']?['content'];
    if (content is String) return content;
    if (content is List) {
      return content
          .whereType<Map>()
          .map((p) => p['text'])
          .whereType<String>()
          .join();
    }
    return null;
  }

  /// The API's own error message when it sent one.
  static String _errorMessage(DioException e) {
    final data = e.response?.data;
    final status = e.response?.statusCode;
    String? message;
    if (data is Map) {
      final error = data['error'];
      message = error is Map ? error['message']?.toString() : error?.toString();
    } else if (data is String && data.isNotEmpty) {
      message = data.length > 200 ? '${data.substring(0, 200)}…' : data;
    }
    message ??= e.message ?? e.type.name;
    return status == null ? message : '$status: $message';
  }
}

/// The texts of a page as the model gets them: by number, so one it merges
/// or skips cannot shift the others into the wrong balloons; with the page
/// before's last lines as context.
String _userMessage(List<String> texts, List<String> context) => jsonEncode({
  if (context.isNotEmpty) 'before': context,
  'texts': {for (final (i, t) in texts.indexed) '${i + 1}': t},
});

/// Request fields that turn a model's thinking off. Reading and
/// translating bubbles needs none, and a thinking model spends most of its
/// time on it (DeepSeek's flash models think by default: 3000–8000 tokens,
/// 15–44 s, for a page; 1.5–3 s without).
///
/// DeepSeek takes `thinking`; OpenAI, Gemini, OpenRouter and Ollama take
/// `reasoning_effort: none`. A model that rejects it (400: one that does
/// not think, or cannot stop) is asked again without it. Claude does not
/// think unless asked.
@visibleForTesting
Map<String, Object> noThinking(String baseUrl) {
  bool on(String domain) {
    final host = Uri.tryParse(baseUrl)?.host ?? '';
    return host == domain || host.endsWith('.$domain');
  }

  if (on('deepseek.com')) {
    return const {
      'thinking': {'type': 'disabled'},
    };
  }
  if (on('anthropic.com')) return const {};
  return const {'reasoning_effort': 'none'};
}

/// Instructions sent before the texts of a page. The same for every page
/// of a comic, so servers that cache a prompt's start (DeepSeek, OpenAI)
/// charge it once.
@visibleForTesting
String translatePrompt(
  String language, {
  String comic = '',
  String notes = '',
}) {
  final style = _styles[language.toLowerCase()];
  return '''
You translate comics (manga, manhwa, manhua) into $language, like a good fan translation: natural, spoken $language that fits each character and situation, not word for word.${comic.isEmpty ? '' : '\nThe comic: "$comic".'}
You get {"before": [...], "texts": {"1": "...", "2": "...", ...}}. "texts" are the speech balloons, captions and signs of one page in reading order, numbered, read by OCR: letters can be misread, and some are noise from the artwork. "before" (if given) are the last translated lines of the page before: keep names, forms of address and tone consistent with them, but do not translate them.
Translate each text on its own, using the others for context and fixing obvious OCR mistakes. Never merge two texts into one or split one: each number gets its own translation. Keep it short enough to fit its balloon. Keep the speaker's tone (casual, polite, rough, childish) and their way of addressing others the same from line to line. Keep "…", "!" and "?" where they carry feeling; sound effects in balloons become $language ones. Keep character names as they are, romanized the usual way.${style == null ? '' : '\n$style'}${notes.isEmpty ? '' : '\nThe reader asks: $notes'}
Reply with JSON only: {"1": "...", "2": "...", ...}, one entry for every number. Use "" for one that is not real text (noise, a page number, a watermark, a scanlation credit).''';
}

/// How dialogue reads naturally, per target language.
const _styles = {
  'indonesian': 'Write like Indonesian manga fan translations: everyday spoken Indonesian in dialogue (nggak, udah, aja, kok, sih, dong, deh, kan where they fit), standard Indonesian for narration and formal speakers. Characters address each other with aku/kamu, or saya/Anda in polite or formal speech; never gue/lo. Keep Japanese honorifics (-san, -kun, -chan, -sama, senpai, sensei) as they are. Avoid stiff word-for-word phrasing.',
  'english': 'Write like a good official localization: natural American English with contractions, idioms that fit the character, no stiff word-for-word phrasing. Keep Japanese honorifics (-san, -kun, -chan, -sama, senpai, sensei) as they are.',
  'malay': 'Write natural, spoken Malay in dialogue (tak, dah, je, la where they fit) and standard Malay in narration. Keep Japanese honorifics as they are.',
};

/// The translations in the model's answer, [count] of them, by number
/// (`{"1": ..., "2": ...}`, also inside `"translations"`); a list is read
/// in order. Missing ones are empty, extra ones dropped. Takes the JSON out
/// of code fences or extra text.
///
/// Throws [FormatException] when no JSON is found.
@visibleForTesting
List<String> parseTranslations(String content, int count) {
  Object? json;
  try {
    json = _extractJson(content);
  } on FormatException {
    // Broken JSON, as small local models write it (a comma inside a
    // string instead of after it, say): take the numbered texts as found.
    final found = {
      for (final m in _numberedText.allMatches(content))
        m.group(1)!: _unescape(m.group(2)!),
    };
    if (found.isEmpty) rethrow;
    json = found;
  }
  if (json is Map && json['translations'] is Object) {
    json = json['translations'];
  }
  String text(Object? v) => (v?.toString() ?? '').trim();
  return switch (json) {
    final List<dynamic> list => [
      for (var i = 0; i < count; i++) i < list.length ? text(list[i]) : '',
    ],
    final Map<dynamic, dynamic> map => [
      for (var i = 1; i <= count; i++) text(map['$i']),
    ],
    _ => List.filled(count, ''),
  };
}

/// `"<number>": "<text>"`, the text with its escapes.
final _numberedText = RegExp(r'"(\d+)"\s*:\s*"((?:[^"\\]|\\.)*)"');

String _unescape(String text) {
  try {
    return jsonDecode('"$text"') as String;
  } on FormatException {
    return text;
  }
}

Object? _extractJson(String content) {
  var s = content.trim();
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(s);
  if (fence != null) s = fence.group(1)!.trim();
  try {
    return jsonDecode(s);
  } on FormatException {
    // Text around the JSON: take the outermost object or list.
  }
  final starts = [s.indexOf('{'), s.indexOf('[')].where((i) => i >= 0);
  if (starts.isEmpty) throw const FormatException('No JSON in the answer');
  final start = starts.reduce(min);
  final end = s.lastIndexOf(s[start] == '{' ? '}' : ']');
  if (end <= start) throw const FormatException('No JSON in the answer');
  return jsonDecode(s.substring(start, end + 1));
}
