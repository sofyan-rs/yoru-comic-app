import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:yoru/core/di/register_module.dart';
import 'package:yoru/core/error/exceptions.dart';
import 'package:yoru/features/translate/domain/entities/page_translation.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';

/// Reads and translates the text of one image through an OpenAI-compatible
/// `chat/completions` API (OpenAI, Gemini, OpenRouter, Claude, Ollama,
/// LM Studio…).
abstract interface class LlmTranslator {
  /// Blocks of the PNG [image] ([width] × [height] px), boxes in fractions
  /// of it.
  Future<List<TextBlock>> translate(
    Uint8List image, {
    required int width,
    required int height,
    required TranslatorConfig config,
  });
}

@LazySingleton(as: LlmTranslator)
class LlmTranslatorImpl implements LlmTranslator {
  LlmTranslatorImpl(@Named(filesDio) this._dio);

  final Dio _dio;

  /// `<baseUrl>|<model>` pairs that answered 400 to [noThinking]'s fields.
  final _thinkingRefused = <String>{};

  /// Local models can take a while for one page.
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
  Future<List<TextBlock>> translate(
    Uint8List image, {
    required int width,
    required int height,
    required TranslatorConfig config,
  }) async {
    final watch = Stopwatch()..start();
    final body = {
      'model': config.model,
      'temperature': 0.2,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': translatePrompt(config.language)},
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/png;base64,${base64Encode(image)}',
              },
            },
          ],
        },
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
      '(${image.length ~/ 1024} KB sent, usage '
      '${data is Map ? jsonEncode(data['usage']) : '?'})',
    );
    final content = _content(response.data);
    if (content == null) {
      throw const ServerException('The model sent no answer');
    }
    try {
      return parseTextBlocks(content, width: width, height: height);
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

/// Instructions sent with each image.
@visibleForTesting
String translatePrompt(String language) =>
    '''
You translate comic pages (manga, manhwa, manhua).
The image is 1000 × 1000 pixels; the page fills its top left part and the rest is white.
Find every piece of text on the page: speech bubbles, thought bubbles, captions, narration boxes and signs. Skip page numbers, watermarks and scanlation credits.
Translate each one into $language. Keep it natural and short enough to fit its bubble. Keep character names as they are.
Reply with JSON only, nothing else:
{"blocks":[{"balloon":[x1,y1,x2,y2],"box":[x1,y1,x2,y2],"text":"translation"}]}
Coordinates are pixels of this 1000 × 1000 image: x1,y1 the top-left corner and x2,y2 the bottom-right (0,0 is the top-left of the image).
"balloon" is the speech balloon, thought bubble or caption box the text is in; for text with none around it, the same as "box".
"box" is the original lettering itself, boxed tightly from the first to the last line.
List the blocks in reading order. If there is no text, reply {"blocks":[]}.''';

/// Reads the model's answer. Takes the JSON out of code fences or extra
/// text, a bare list or `{"blocks": [...]}`, boxes as `box`, `bbox` or
/// `box_2d`, and a `balloon` (or `bubble`) around each when given.
/// Coordinates are read as 0–1000 (as asked); above 1000 as
/// pixels of the [width] × [height] image, and all at or under 1 as
/// fractions.
///
/// Throws [FormatException] when no JSON is found.
List<TextBlock> parseTextBlocks(
  String content, {
  required int width,
  required int height,
}) {
  final json = _extractJson(content);
  final List<dynamic> items = switch (json) {
    final List<dynamic> list => list,
    final Map<dynamic, dynamic> map => switch (map['blocks'] ??
        map['texts'] ??
        map['items']) {
      final List<dynamic> list => list,
      _ => const [],
    },
    _ => const [],
  };

  List<double>? numbers(Object? box) {
    if (box is! List || box.length != 4) return null;
    final values = box.map((v) => v is num ? v.toDouble() : null).toList();
    return values.contains(null) ? null : values.cast<double>();
  }

  final raw = <(List<double>, List<double>?, String)>[];
  for (final item in items) {
    if (item is! Map) continue;
    final text = (item['text'] ?? item['translation'])?.toString().trim();
    final box = numbers(item['box'] ?? item['bbox'] ?? item['box_2d']);
    if (text == null || text.isEmpty || box == null) continue;
    raw.add((box, numbers(item['balloon'] ?? item['bubble']), text));
  }
  if (raw.isEmpty) return const [];

  final largest = raw.expand((r) => [...r.$1, ...?r.$2]).reduce(max);
  final (double sx, double sy) = largest <= 1
      ? (1, 1)
      : largest <= 1000
      ? (1000, 1000)
      : (width.toDouble(), height.toDouble());

  PageBox scaled(List<double> box) {
    final x1 = (box[0] / sx).clamp(0.0, 1.0);
    final y1 = (box[1] / sy).clamp(0.0, 1.0);
    final x2 = (box[2] / sx).clamp(0.0, 1.0);
    final y2 = (box[3] / sy).clamp(0.0, 1.0);
    return (
      left: min(x1, x2),
      top: min(y1, y2),
      right: max(x1, x2),
      bottom: max(y1, y2),
    );
  }

  final blocks = <TextBlock>[];
  for (final (box, balloon, text) in raw) {
    final b = scaled(box);
    final block = TextBlock(
      left: b.left,
      top: b.top,
      right: b.right,
      bottom: b.bottom,
      text: text,
      balloon: balloon == null ? null : scaled(balloon),
    );
    if (block.width <= 0.005 || block.height <= 0.005) continue;
    blocks.add(block);
  }
  return blocks;
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
