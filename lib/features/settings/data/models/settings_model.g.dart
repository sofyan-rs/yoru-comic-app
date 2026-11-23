// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsModel _$SettingsModelFromJson(Map<String, dynamic> json) =>
    SettingsModel(
      themeMode:
          $enumDecodeNullable(
            _$AppThemeModeEnumMap,
            json['themeMode'],
            unknownValue: AppThemeMode.system,
          ) ??
          AppThemeMode.system,
      language:
          $enumDecodeNullable(
            _$AppLanguageEnumMap,
            json['language'],
            unknownValue: AppLanguage.english,
          ) ??
          AppLanguage.english,
      readingDirection:
          $enumDecodeNullable(
            _$ReadingDirectionEnumMap,
            json['readingDirection'],
            unknownValue: ReadingDirection.vertical,
          ) ??
          ReadingDirection.vertical,
      pageFit:
          $enumDecodeNullable(
            _$PageFitEnumMap,
            json['pageFit'],
            unknownValue: PageFit.width,
          ) ??
          PageFit.width,
      readerWidth:
          $enumDecodeNullable(
            _$ReaderWidthEnumMap,
            json['readerWidth'],
            unknownValue: ReaderWidth.medium,
          ) ??
          ReaderWidth.medium,
      twoPages: json['twoPages'] as bool? ?? false,
      keepScreenOn: json['keepScreenOn'] as bool? ?? true,
      pageGap: json['pageGap'] as bool? ?? false,
      progressBar: json['progressBar'] as bool? ?? true,
      infiniteScroll: json['infiniteScroll'] as bool? ?? false,
      autoScrollSpeed: (json['autoScrollSpeed'] as num?)?.toInt() ?? 3,
      incognito: json['incognito'] as bool? ?? false,
      kururinSound: json['kururinSound'] as bool? ?? true,
      lalalaUntilFinish: json['lalalaUntilFinish'] as bool? ?? false,
      bookmarkGrouping:
          $enumDecodeNullable(
            _$BookmarkGroupingEnumMap,
            json['bookmarkGrouping'],
            unknownValue: BookmarkGrouping.status,
          ) ??
          BookmarkGrouping.status,
      bookmarkSort:
          $enumDecodeNullable(
            _$BookmarkSortEnumMap,
            json['bookmarkSort'],
            unknownValue: BookmarkSort.updated,
          ) ??
          BookmarkSort.updated,
      bookmarkSortDirection:
          $enumDecodeNullable(
            _$SortDirectionEnumMap,
            json['bookmarkSortDirection'],
            unknownValue: SortDirection.descending,
          ) ??
          SortDirection.descending,
      dnsOverHttps: json['dnsOverHttps'] as String? ?? '',
      translateBaseUrl: json['translateBaseUrl'] as String? ?? '',
      translateApiKey: json['translateApiKey'] as String? ?? '',
      translateModel: json['translateModel'] as String? ?? '',
      translateLanguage: json['translateLanguage'] as String? ?? '',
      translateEngine: json['translateEngine'] as String? ?? 'api',
      translateNotes: json['translateNotes'] as String? ?? '',
      translateScript: json['translateScript'] as String? ?? 'auto',
      translateUppercase: json['translateUppercase'] as bool? ?? true,
      translateFontPath: json['translateFontPath'] as String? ?? '',
    );

Map<String, dynamic> _$SettingsModelToJson(SettingsModel instance) =>
    <String, dynamic>{
      'themeMode': _$AppThemeModeEnumMap[instance.themeMode]!,
      'language': _$AppLanguageEnumMap[instance.language]!,
      'readingDirection': _$ReadingDirectionEnumMap[instance.readingDirection]!,
      'pageFit': _$PageFitEnumMap[instance.pageFit]!,
      'readerWidth': _$ReaderWidthEnumMap[instance.readerWidth]!,
      'twoPages': instance.twoPages,
      'keepScreenOn': instance.keepScreenOn,
      'pageGap': instance.pageGap,
      'progressBar': instance.progressBar,
      'infiniteScroll': instance.infiniteScroll,
      'autoScrollSpeed': instance.autoScrollSpeed,
      'incognito': instance.incognito,
      'kururinSound': instance.kururinSound,
      'lalalaUntilFinish': instance.lalalaUntilFinish,
      'bookmarkGrouping': _$BookmarkGroupingEnumMap[instance.bookmarkGrouping]!,
      'bookmarkSort': _$BookmarkSortEnumMap[instance.bookmarkSort]!,
      'bookmarkSortDirection':
          _$SortDirectionEnumMap[instance.bookmarkSortDirection]!,
      'dnsOverHttps': instance.dnsOverHttps,
      'translateBaseUrl': instance.translateBaseUrl,
      'translateApiKey': instance.translateApiKey,
      'translateModel': instance.translateModel,
      'translateLanguage': instance.translateLanguage,
      'translateEngine': instance.translateEngine,
      'translateNotes': instance.translateNotes,
      'translateScript': instance.translateScript,
      'translateUppercase': instance.translateUppercase,
      'translateFontPath': instance.translateFontPath,
    };

const _$AppThemeModeEnumMap = {
  AppThemeMode.system: 'system',
  AppThemeMode.light: 'light',
  AppThemeMode.dark: 'dark',
};

const _$AppLanguageEnumMap = {
  AppLanguage.english: 'english',
  AppLanguage.indonesian: 'indonesian',
};

const _$ReadingDirectionEnumMap = {
  ReadingDirection.vertical: 'vertical',
  ReadingDirection.rightToLeft: 'rightToLeft',
  ReadingDirection.leftToRight: 'leftToRight',
};

const _$PageFitEnumMap = {PageFit.width: 'width', PageFit.height: 'height'};

const _$ReaderWidthEnumMap = {
  ReaderWidth.narrow: 'narrow',
  ReaderWidth.medium: 'medium',
  ReaderWidth.wide: 'wide',
  ReaderWidth.full: 'full',
};

const _$BookmarkGroupingEnumMap = {
  BookmarkGrouping.status: 'status',
  BookmarkGrouping.source: 'source',
  BookmarkGrouping.category: 'category',
};

const _$BookmarkSortEnumMap = {
  BookmarkSort.updated: 'updated',
  BookmarkSort.title: 'title',
  BookmarkSort.chapters: 'chapters',
  BookmarkSort.latestChapter: 'latestChapter',
  BookmarkSort.added: 'added',
  BookmarkSort.lastRead: 'lastRead',
  BookmarkSort.unread: 'unread',
};

const _$SortDirectionEnumMap = {
  SortDirection.ascending: 'ascending',
  SortDirection.descending: 'descending',
};
