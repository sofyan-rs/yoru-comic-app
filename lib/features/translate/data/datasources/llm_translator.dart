import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:yoru/core/constants/texts.dart';
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

  /// Tries of a request a server answers 429 (too many requests) to.
  static const _rateLimitTries = 3;

  /// [_send], asked again after a 429 (a free plan's requests per second,
  /// pages translated side by side): after the server's `Retry-After`, or
  /// 2, 4 and 8 seconds.
  Future<Response<dynamic>> _post(
    TranslatorConfig config,
    Map<String, Object> body,
  ) async {
    for (var attempt = 1; ; attempt++) {
      try {
        return await _send(config, body);
      } on DioException catch (e) {
        if (e.response?.statusCode != 429 || attempt > _rateLimitTries) {
          rethrow;
        }
        final after = int.tryParse(
          e.response?.headers.value('retry-after') ?? '',
        );
        final wait = Duration(seconds: min(after ?? 1 << attempt, 30));
        debugPrint('Translate: 429, asking again in ${wait.inSeconds} s');
        await Future<void>.delayed(wait);
      }
    }
  }

  Future<Response<dynamic>> _send(
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
    final first = await _ask(texts, config, context);
    final missing = [
      for (var i = 0; i < texts.length; i++)
        if (first[i] == null) i,
    ];
    if (missing.isEmpty) return [for (final t in first) t!];
    // A small model can leave numbers out (often the last ones): those
    // alone, once more, rather than leaving their balloons untranslated.
    debugPrint('Translate: ${missing.length} left out, asking again');
    final again = await _ask(
      [for (final i in missing) texts[i]],
      config,
      context,
    );
    for (final (n, i) in missing.indexed) {
      first[i] = again[n];
    }
    return [for (final t in first) t ?? ''];
  }

  /// [texts] sent to the server in one request: a translation each, or
  /// null for one the answer left out.
  Future<List<String?>> _ask(
    List<String> texts,
    TranslatorConfig config,
    List<String> context,
  ) async {
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
      return parseAnswer(content, texts.length);
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
  static String _errorMessage(DioException e) => llmErrorMessage(
    status: e.response?.statusCode,
    data: e.response?.data,
    type: e.type,
  );
}

/// What went wrong with a request, for the reader: what the [status] (or
/// the connection error [type]) means in plain words, then the server's
/// own reason from its answer ([data]) on a second line when it gives one.
@visibleForTesting
String llmErrorMessage({
  int? status,
  Object? data,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final t = AppText.t;
  final summary = switch (status) {
    null => switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => t.translateErrorTimeout,
      DioExceptionType.badCertificate => t.translateErrorCertificate,
      DioExceptionType.cancel => t.translateErrorCancelled,
      _ => t.translateErrorConnection,
    },
    401 || 403 => t.translateErrorKey,
    402 => t.translateErrorPayment,
    404 => t.translateErrorNotFound,
    408 || 504 => t.translateErrorTimeout,
    413 => t.translateErrorTooLong,
    429 => t.translateErrorRateLimit,
    >= 500 => t.translateErrorServer,
    _ => t.translateErrorRefused,
  };
  final reason = _serverReason(data);
  final head = status == null ? summary : '$summary ($status)';
  return reason == null ? head : '$head\n$reason';
}

/// The reason a server gives in its error answer: OpenAI's
/// `{"error": {"message"}}`, Mistral's `{"message"}`, FastAPI's
/// `{"detail"}`, or a short plain text; null when there is none.
String? _serverReason(Object? data) {
  if (data is String) {
    final text = data.trim();
    if (text.isEmpty || text.startsWith('<')) return null;
    try {
      return _serverReason(jsonDecode(text));
    } on FormatException {
      return _short(text);
    }
  }
  if (data is! Map) return null;
  Object? found = data['error'];
  if (found is Map) found = found['message'] ?? found['msg'];
  found ??= data['message'] ?? data['detail'] ?? data['error_description'];
  if (found is List && found.isNotEmpty) {
    final first = found.first;
    found = first is Map ? first['msg'] ?? first['message'] : first;
  }
  final text = found?.toString().trim() ?? '';
  return text.isEmpty ? null : _short(text);
}

String _short(String text) =>
    text.length > 160 ? '${text.substring(0, 160)}…' : text;

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
Translate comic text (manga, manhwa, manhua) into $language like a good fan translation: natural, spoken $language, not word for word.${comic.isEmpty ? '' : '\nThe comic: "$comic".'}
Input: {"before": [...], "texts": {"1": "...", ...}}. "texts": balloons, captions and signs in reading order (one page or a few), read by OCR, so letters may be misread, words run together ("YOUREHUGE") or a balloon cut short: translate what is there, fixing obvious mistakes. "before": lines translated just before, for consistent names, address and tone; do not translate them.
One translation per number: never merge or split. Keep it short, keep each speaker's tone, keep names as they are. Spoken sounds (ah, ugh) are dialogue; sound effects drawn in the art (BOOM, 쾅) get "".${style == null ? '' : '\n$style'}${notes.isEmpty ? '' : '\nThe reader asks: $notes'}
Reply with JSON only: {"1": "...", ...}, every number. "" only for what clearly is not story (noise, page number, watermark, credits, cover title, plugs); when in doubt, translate.''';
}

/// How dialogue reads naturally, per target language.
const _styles = {
  'indonesian': 'Indonesian fan-translation style: everyday spoken Indonesian in dialogue (nggak, udah, aja, kok, sih, dong where they fit), standard Indonesian in narration. Address: aku/kamu, or saya/Anda when polite; never gue/lo. Keep honorifics (-san, -kun, -chan, -sama, senpai, sensei).',
  'english': 'Official-localization style: natural American English with contractions. Keep honorifics (-san, -kun, -chan, -sama, senpai, sensei).',
  'malay': 'Write natural, spoken Malay in dialogue (tak, dah, je, la where they fit) and standard Malay in narration. Keep Japanese honorifics as they are.',
};

/// The translations in the model's answer, [count] of them, by number
/// (`{"1": ..., "2": ...}`, also inside `"translations"`); a list is read
/// in order. Missing ones are empty, extra ones dropped. Takes the JSON out
/// of code fences or extra text.
///
/// Throws [FormatException] when no JSON is found.
@visibleForTesting
List<String> parseTranslations(String content, int count) => [
  for (final t in parseAnswer(content, count)) t ?? '',
];

/// [parseTranslations], with null for a number the answer left out (an
/// empty string is a text the model meant to drop).
@visibleForTesting
List<String?> parseAnswer(String content, int count) {
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
  String? text(Object? v) => v?.toString().trim();
  return switch (json) {
    final List<dynamic> list => [
      for (var i = 0; i < count; i++) i < list.length ? text(list[i]) : null,
    ],
    final Map<dynamic, dynamic> map => [
      for (var i = 1; i <= count; i++) text(map['$i']),
    ],
    _ => List<String?>.filled(count, null),
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
