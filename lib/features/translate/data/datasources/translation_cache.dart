import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yoru/features/translate/domain/entities/page_translation.dart';

/// Translated pages as small JSON files in the app's cache directory
/// (`translations/<sha1>.json`), so a page read again costs no request.
/// Kept out of Hive: it is a cache the system may clear.
abstract interface class TranslationCache {
  Future<PageTranslation?> get(String key);

  Future<void> put(String key, PageTranslation translation);

  Future<void> remove(String key);
}

@LazySingleton(as: TranslationCache)
class TranslationCacheImpl implements TranslationCache {
  late final Future<Directory> _dir = () async {
    final dir = Directory(
      '${(await getApplicationCacheDirectory()).path}/translations',
    );
    await dir.create(recursive: true);
    return dir;
  }();

  Future<File> _file(String key) async =>
      File('${(await _dir).path}/${sha1.convert(utf8.encode(key))}.json');

  @override
  Future<PageTranslation?> get(String key) async {
    try {
      final file = await _file(key);
      if (!await file.exists()) return null;
      return PageTranslation.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('TranslationCache: $e');
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      final file = await _file(key);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('TranslationCache: $e');
    }
  }

  @override
  Future<void> put(String key, PageTranslation translation) async {
    try {
      await (await _file(key)).writeAsString(jsonEncode(translation));
    } catch (e) {
      debugPrint('TranslationCache: $e');
    }
  }
}
