import 'package:yoru/features/settings/domain/entities/app_settings.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_model.g.dart';

/// Stored settings. Missing or unknown values fall back to the defaults.
@JsonSerializable()
class SettingsModel {
  const SettingsModel({
    this.themeMode = AppThemeMode.system,
    this.language = AppLanguage.english,
    this.readingDirection = ReadingDirection.vertical,
    this.pageFit = PageFit.width,
    this.readerWidth = ReaderWidth.medium,
    this.twoPages = false,
    this.keepScreenOn = true,
    this.pageGap = false,
    this.progressBar = true,
    this.infiniteScroll = false,
    this.autoScrollSpeed = 3,
    this.incognito = false,
    this.kururinSound = true,
    this.lalalaUntilFinish = false,
    this.bookmarkGrouping = BookmarkGrouping.status,
    this.bookmarkSort = BookmarkSort.updated,
    this.bookmarkSortDirection = SortDirection.descending,
    this.dnsOverHttps = '',
    this.translateBaseUrl = '',
    this.translateApiKey = '',
    this.translateModel = '',
    this.translateLanguage = '',
    this.translateEngine = 'api',
    this.translateNotes = '',
    this.translateScript = 'auto',
    this.translateUppercase = true,
    this.translateFontPath = '',
  });

  factory SettingsModel.fromEntity(AppSettings e) => SettingsModel(
    themeMode: e.themeMode,
    language: e.language,
    readingDirection: e.readingDirection,
    pageFit: e.pageFit,
    readerWidth: e.readerWidth,
    twoPages: e.twoPages,
    keepScreenOn: e.keepScreenOn,
    pageGap: e.pageGap,
    progressBar: e.progressBar,
    infiniteScroll: e.infiniteScroll,
    autoScrollSpeed: e.autoScrollSpeed,
    incognito: e.incognito,
    kururinSound: e.kururinSound,
    lalalaUntilFinish: e.lalalaUntilFinish,
    bookmarkGrouping: e.bookmarkGrouping,
    bookmarkSort: e.bookmarkSort,
    bookmarkSortDirection: e.bookmarkSortDirection,
    dnsOverHttps: e.dnsOverHttps,
    translateBaseUrl: e.translateBaseUrl,
    translateApiKey: e.translateApiKey,
    translateModel: e.translateModel,
    translateLanguage: e.translateLanguage,
    translateEngine: e.translateEngine,
    translateNotes: e.translateNotes,
    translateScript: e.translateScript,
    translateUppercase: e.translateUppercase,
    translateFontPath: e.translateFontPath,
  );

  factory SettingsModel.fromJson(Map<String, dynamic> json) =>
      _$SettingsModelFromJson(json);

  @JsonKey(unknownEnumValue: AppThemeMode.system)
  final AppThemeMode themeMode;

  @JsonKey(unknownEnumValue: AppLanguage.english)
  final AppLanguage language;

  @JsonKey(unknownEnumValue: ReadingDirection.vertical)
  final ReadingDirection readingDirection;

  @JsonKey(unknownEnumValue: PageFit.width)
  final PageFit pageFit;

  @JsonKey(unknownEnumValue: ReaderWidth.medium)
  final ReaderWidth readerWidth;

  final bool twoPages;

  final bool keepScreenOn;
  final bool pageGap;
  final bool progressBar;
  final bool infiniteScroll;
  final int autoScrollSpeed;
  final bool incognito;
  final bool kururinSound;
  final bool lalalaUntilFinish;

  @JsonKey(unknownEnumValue: BookmarkGrouping.status)
  final BookmarkGrouping bookmarkGrouping;

  @JsonKey(unknownEnumValue: BookmarkSort.updated)
  final BookmarkSort bookmarkSort;

  @JsonKey(unknownEnumValue: SortDirection.descending)
  final SortDirection bookmarkSortDirection;

  final String dnsOverHttps;
  final String translateBaseUrl;
  final String translateApiKey;
  final String translateModel;
  final String translateLanguage;
  final String translateEngine;
  final String translateNotes;
  final String translateScript;
  final bool translateUppercase;
  final String translateFontPath;

  Map<String, dynamic> toJson() => _$SettingsModelToJson(this);

  AppSettings toEntity() => AppSettings(
    themeMode: themeMode,
    language: language,
    readingDirection: readingDirection,
    pageFit: pageFit,
    readerWidth: readerWidth,
    twoPages: twoPages,
    keepScreenOn: keepScreenOn,
    pageGap: pageGap,
    progressBar: progressBar,
    infiniteScroll: infiniteScroll,
    autoScrollSpeed: autoScrollSpeed.clamp(autoScrollMin, autoScrollMax),
    incognito: incognito,
    kururinSound: kururinSound,
    lalalaUntilFinish: lalalaUntilFinish,
    bookmarkGrouping: bookmarkGrouping,
    bookmarkSort: bookmarkSort,
    bookmarkSortDirection: bookmarkSortDirection,
    dnsOverHttps: dnsOverHttps,
    translateBaseUrl: translateBaseUrl,
    translateApiKey: translateApiKey,
    translateModel: translateModel,
    translateLanguage: translateLanguage,
    translateEngine: translateEngine,
    translateNotes: translateNotes,
    translateScript: translateScript,
    translateUppercase: translateUppercase,
    translateFontPath: translateFontPath,
  );
}
