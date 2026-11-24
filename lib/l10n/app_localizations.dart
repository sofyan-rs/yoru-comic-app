import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get goodNight;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmark;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @historyTab.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTab;

  /// No description provided for @newSeries.
  ///
  /// In en, this message translates to:
  /// **'New series'**
  String get newSeries;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest updates'**
  String get latest;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get continueReading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @chapterList.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chapterList;

  /// No description provided for @synopsis.
  ///
  /// In en, this message translates to:
  /// **'Synopsis'**
  String get synopsis;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @addedToBookmark.
  ///
  /// In en, this message translates to:
  /// **'Added to bookmarks'**
  String get addedToBookmark;

  /// No description provided for @removedFromBookmark.
  ///
  /// In en, this message translates to:
  /// **'Removed from bookmarks'**
  String get removedFromBookmark;

  /// No description provided for @saveImg.
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get saveImg;

  /// No description provided for @seeCover.
  ///
  /// In en, this message translates to:
  /// **'View cover'**
  String get seeCover;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @chapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get chapter;

  /// No description provided for @chapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chapters;

  /// No description provided for @released.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get released;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get startReading;

  /// No description provided for @addBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add to bookmarks'**
  String get addBookmark;

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove from bookmarks'**
  String get removeBookmark;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markRead;

  /// No description provided for @markUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get markUnread;

  /// No description provided for @searchChapter.
  ///
  /// In en, this message translates to:
  /// **'Search chapter'**
  String get searchChapter;

  /// No description provided for @searchChapterHint.
  ///
  /// In en, this message translates to:
  /// **'Chapter number'**
  String get searchChapterHint;

  /// No description provided for @sortChapter.
  ///
  /// In en, this message translates to:
  /// **'Sort chapters'**
  String get sortChapter;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareSuffix.
  ///
  /// In en, this message translates to:
  /// **'read it on Yoru'**
  String get shareSuffix;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopied;

  /// No description provided for @titleCopied.
  ///
  /// In en, this message translates to:
  /// **'Title copied to clipboard'**
  String get titleCopied;

  /// No description provided for @copyTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy title'**
  String get copyTitle;

  /// No description provided for @successSaveImg.
  ///
  /// In en, this message translates to:
  /// **'Image saved to gallery.'**
  String get successSaveImg;

  /// No description provided for @successSaveImgFile.
  ///
  /// In en, this message translates to:
  /// **'Image saved.'**
  String get successSaveImgFile;

  /// No description provided for @failedSaveImg.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save image.'**
  String get failedSaveImg;

  /// No description provided for @bookmarkEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get bookmarkEmpty;

  /// No description provided for @bookmarkEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark icon on a comic\'s page to save it here.'**
  String get bookmarkEmptyHint;

  /// No description provided for @searchBookmarkHint.
  ///
  /// In en, this message translates to:
  /// **'Search bookmarks'**
  String get searchBookmarkHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get filterUpdated;

  /// No description provided for @filterFinished.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterFinished;

  /// No description provided for @hasUpdate.
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get hasUpdate;

  /// No description provided for @deleteBookmark.
  ///
  /// In en, this message translates to:
  /// **'Delete bookmarks'**
  String get deleteBookmark;

  /// No description provided for @deleteBookmarkDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove these comics from your bookmarks?'**
  String get deleteBookmarkDescription;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// No description provided for @markedAllRead.
  ///
  /// In en, this message translates to:
  /// **'marked as read'**
  String get markedAllRead;

  /// No description provided for @markAllUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark all chapters as unread'**
  String get markAllUnread;

  /// No description provided for @markAllUnreadDescription.
  ///
  /// In en, this message translates to:
  /// **'Reading progress of these comics is removed, and they leave History.'**
  String get markAllUnreadDescription;

  /// No description provided for @markedAllUnread.
  ///
  /// In en, this message translates to:
  /// **'marked as unread'**
  String get markedAllUnread;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search comics'**
  String get searchHint;

  /// No description provided for @comicNotFound.
  ///
  /// In en, this message translates to:
  /// **'No comics found'**
  String get comicNotFound;

  /// No description provided for @comicNotFoundFilter.
  ///
  /// In en, this message translates to:
  /// **'Try changing or resetting the filters.'**
  String get comicNotFoundFilter;

  /// No description provided for @comicNotFoundSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword.'**
  String get comicNotFoundSearch;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genre;

  /// No description provided for @sortShort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortShort;

  /// No description provided for @sortShortLong.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortShortLong;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get showResults;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @exploreSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search comic titles'**
  String get exploreSearchHint;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reading history yet'**
  String get historyEmpty;

  /// No description provided for @historyEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Chapters you read will show up here.'**
  String get historyEmptyHint;

  /// No description provided for @swipeToDelete.
  ///
  /// In en, this message translates to:
  /// **'swipe to delete'**
  String get swipeToDelete;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @deleteLastChapter.
  ///
  /// In en, this message translates to:
  /// **'Last chapter only'**
  String get deleteLastChapter;

  /// No description provided for @deleteAllChapters.
  ///
  /// In en, this message translates to:
  /// **'All chapters of this comic'**
  String get deleteAllChapters;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @clearHistoryConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all saved reading history?'**
  String get clearHistoryConfirmation;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'Reading history'**
  String get history;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// No description provided for @clearCacheDescription.
  ///
  /// In en, this message translates to:
  /// **'Library, covers and downloads stay safe'**
  String get clearCacheDescription;

  /// No description provided for @clearCacheScope.
  ///
  /// In en, this message translates to:
  /// **'Chapter pages · temporary data'**
  String get clearCacheScope;

  /// No description provided for @cacheImages.
  ///
  /// In en, this message translates to:
  /// **'Chapter pages'**
  String get cacheImages;

  /// No description provided for @cacheCovers.
  ///
  /// In en, this message translates to:
  /// **'Covers'**
  String get cacheCovers;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cacheCleared;

  /// No description provided for @removed.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get removed;

  /// No description provided for @kept.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get kept;

  /// No description provided for @clearCacheConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Saved chapter pages are deleted and downloaded again when you open them. Covers, bookmarks, reading history and downloads are kept.'**
  String get clearCacheConfirmation;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Back up data'**
  String get backupData;

  /// No description provided for @backupDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks, categories and reading history'**
  String get backupDataDescription;

  /// No description provided for @successBackupData.
  ///
  /// In en, this message translates to:
  /// **'Data backed up'**
  String get successBackupData;

  /// No description provided for @failedBackupData.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t back up data'**
  String get failedBackupData;

  /// No description provided for @restoreData.
  ///
  /// In en, this message translates to:
  /// **'Restore data'**
  String get restoreData;

  /// No description provided for @restoreDataDescription.
  ///
  /// In en, this message translates to:
  /// **'From a backup file'**
  String get restoreDataDescription;

  /// No description provided for @successRestoreData.
  ///
  /// In en, this message translates to:
  /// **'Data restored'**
  String get successRestoreData;

  /// No description provided for @failedRestoreData.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore data'**
  String get failedRestoreData;

  /// No description provided for @syncDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive sync'**
  String get syncDrive;

  /// No description provided for @syncDriveDescription.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks and reading history on all your devices'**
  String get syncDriveDescription;

  /// No description provided for @syncSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get syncSigningIn;

  /// No description provided for @syncSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in to Google'**
  String get syncSignInFailed;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncing;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed, tap to try again'**
  String get syncFailed;

  /// No description provided for @syncNever.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get syncNever;

  /// No description provided for @syncLast.
  ///
  /// In en, this message translates to:
  /// **'Last synced'**
  String get syncLast;

  /// No description provided for @syncSignOut.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Google Drive'**
  String get syncSignOut;

  /// No description provided for @syncSignOutDescription.
  ///
  /// In en, this message translates to:
  /// **'Syncing stops. Data on this device stays saved.'**
  String get syncSignOutDescription;

  /// No description provided for @syncDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get syncDisconnect;

  /// No description provided for @googleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get googleDrive;

  /// No description provided for @bugReport.
  ///
  /// In en, this message translates to:
  /// **'Report a bug or suggestion'**
  String get bugReport;

  /// No description provided for @bugReportDescription.
  ///
  /// In en, this message translates to:
  /// **'Opens GitHub Issues'**
  String get bugReportDescription;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About the app'**
  String get aboutApp;

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Developer and website'**
  String get aboutAppDescription;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Kurodev website'**
  String get website;

  /// No description provided for @giveSupport.
  ///
  /// In en, this message translates to:
  /// **'Give support'**
  String get giveSupport;

  /// No description provided for @linkFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link'**
  String get linkFailed;

  /// No description provided for @chaptersRead.
  ///
  /// In en, this message translates to:
  /// **'Chapters read'**
  String get chaptersRead;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @kururinSound.
  ///
  /// In en, this message translates to:
  /// **'Lalala pipipi sound'**
  String get kururinSound;

  /// No description provided for @kururinSoundDescription.
  ///
  /// In en, this message translates to:
  /// **'Plays while pulling to refresh Home'**
  String get kururinSoundDescription;

  /// No description provided for @lalalaUntilFinish.
  ///
  /// In en, this message translates to:
  /// **'Play until finish'**
  String get lalalaUntilFinish;

  /// No description provided for @lalalaUntilFinishDescription.
  ///
  /// In en, this message translates to:
  /// **'Keeps the refresh animation going until the song ends'**
  String get lalalaUntilFinishDescription;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @downloadsDescription.
  ///
  /// In en, this message translates to:
  /// **'Chapters for offline reading'**
  String get downloadsDescription;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloadQueued.
  ///
  /// In en, this message translates to:
  /// **'queued for download'**
  String get downloadQueued;

  /// No description provided for @downloadQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get downloadQueue;

  /// No description provided for @downloadWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get downloadWaiting;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get downloadFailed;

  /// No description provided for @downloadRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry download'**
  String get downloadRetry;

  /// No description provided for @downloadRetryAll.
  ///
  /// In en, this message translates to:
  /// **'Retry all'**
  String get downloadRetryAll;

  /// No description provided for @downloadCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get downloadCancel;

  /// No description provided for @downloadsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get downloadsEmpty;

  /// No description provided for @downloadsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Select chapters on a comic\'s page, then tap the download icon.'**
  String get downloadsEmptyHint;

  /// No description provided for @downloadedChapters.
  ///
  /// In en, this message translates to:
  /// **'Downloaded chapters'**
  String get downloadedChapters;

  /// No description provided for @storageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage used'**
  String get storageUsed;

  /// No description provided for @deleteDownloads.
  ///
  /// In en, this message translates to:
  /// **'Delete downloads'**
  String get deleteDownloads;

  /// No description provided for @deleteComicDownloads.
  ///
  /// In en, this message translates to:
  /// **'Delete all downloaded chapters of this comic?'**
  String get deleteComicDownloads;

  /// No description provided for @clearDownloads.
  ///
  /// In en, this message translates to:
  /// **'Delete all downloads'**
  String get clearDownloads;

  /// No description provided for @clearDownloadsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'All downloaded chapters are deleted from this device. Bookmarks and reading history are kept.'**
  String get clearDownloadsConfirmation;

  /// No description provided for @downloadedLabel.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloadedLabel;

  /// No description provided for @downloadNotificationRunning.
  ///
  /// In en, this message translates to:
  /// **'Downloading chapters'**
  String get downloadNotificationRunning;

  /// No description provided for @downloadNotificationDone.
  ///
  /// In en, this message translates to:
  /// **'Downloads complete'**
  String get downloadNotificationDone;

  /// No description provided for @downloadNotificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Some downloads failed'**
  String get downloadNotificationFailed;

  /// No description provided for @checkUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkUpdate;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get updateRetry;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get updateDownloading;

  /// No description provided for @updateInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing update'**
  String get updateInstalling;

  /// No description provided for @updateApprovalHint.
  ///
  /// In en, this message translates to:
  /// **'If asked, approve the installation in the system prompt.'**
  String get updateApprovalHint;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed. Try again later.'**
  String get updateFailed;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest version'**
  String get upToDate;

  /// No description provided for @checkUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates'**
  String get checkUpdateFailed;

  /// No description provided for @viewRelease.
  ///
  /// In en, this message translates to:
  /// **'View on GitHub'**
  String get viewRelease;

  /// No description provided for @readerSettings.
  ///
  /// In en, this message translates to:
  /// **'Reader settings'**
  String get readerSettings;

  /// No description provided for @readingDirection.
  ///
  /// In en, this message translates to:
  /// **'Reading direction'**
  String get readingDirection;

  /// No description provided for @directionVertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get directionVertical;

  /// No description provided for @directionRtl.
  ///
  /// In en, this message translates to:
  /// **'Right to left'**
  String get directionRtl;

  /// No description provided for @directionLtr.
  ///
  /// In en, this message translates to:
  /// **'Left to right'**
  String get directionLtr;

  /// No description provided for @pageSize.
  ///
  /// In en, this message translates to:
  /// **'Page size'**
  String get pageSize;

  /// No description provided for @fitWidth.
  ///
  /// In en, this message translates to:
  /// **'Fit width'**
  String get fitWidth;

  /// No description provided for @fitHeight.
  ///
  /// In en, this message translates to:
  /// **'Fit height'**
  String get fitHeight;

  /// No description provided for @pageWidth.
  ///
  /// In en, this message translates to:
  /// **'Page width'**
  String get pageWidth;

  /// No description provided for @widthNarrow.
  ///
  /// In en, this message translates to:
  /// **'Narrow'**
  String get widthNarrow;

  /// No description provided for @widthMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get widthMedium;

  /// No description provided for @widthWide.
  ///
  /// In en, this message translates to:
  /// **'Wide'**
  String get widthWide;

  /// No description provided for @widthFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get widthFull;

  /// No description provided for @twoPages.
  ///
  /// In en, this message translates to:
  /// **'Two pages'**
  String get twoPages;

  /// No description provided for @twoPagesHint.
  ///
  /// In en, this message translates to:
  /// **'Side by side when the window is wider than tall'**
  String get twoPagesHint;

  /// No description provided for @incognito.
  ///
  /// In en, this message translates to:
  /// **'Incognito mode'**
  String get incognito;

  /// No description provided for @incognitoDescription.
  ///
  /// In en, this message translates to:
  /// **'Reading is not saved to history'**
  String get incognitoDescription;

  /// No description provided for @keepScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on'**
  String get keepScreenOn;

  /// No description provided for @keepScreenOnHint.
  ///
  /// In en, this message translates to:
  /// **'While reading a chapter'**
  String get keepScreenOnHint;

  /// No description provided for @pageGap.
  ///
  /// In en, this message translates to:
  /// **'Page gap'**
  String get pageGap;

  /// No description provided for @pageGapHint.
  ///
  /// In en, this message translates to:
  /// **'8px line between pages'**
  String get pageGapHint;

  /// No description provided for @progressBar.
  ///
  /// In en, this message translates to:
  /// **'Progress bar'**
  String get progressBar;

  /// No description provided for @progressBarHint.
  ///
  /// In en, this message translates to:
  /// **'Thin line at the bottom while reading'**
  String get progressBarHint;

  /// No description provided for @infiniteScroll.
  ///
  /// In en, this message translates to:
  /// **'Infinite scroll'**
  String get infiniteScroll;

  /// No description provided for @infiniteScrollHint.
  ///
  /// In en, this message translates to:
  /// **'Chapters run on into each other'**
  String get infiniteScrollHint;

  /// No description provided for @chapterLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the chapter'**
  String get chapterLoadFailed;

  /// No description provided for @chaptersLoadingSlow.
  ///
  /// In en, this message translates to:
  /// **'Still loading the chapter list. Long series take a while.'**
  String get chaptersLoadingSlow;

  /// No description provided for @pageShort.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get pageShort;

  /// No description provided for @autoScrollSpeed.
  ///
  /// In en, this message translates to:
  /// **'Scroll speed'**
  String get autoScrollSpeed;

  /// No description provided for @autoScrollHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the screen to pause'**
  String get autoScrollHint;

  /// No description provided for @autoScrollStart.
  ///
  /// In en, this message translates to:
  /// **'Start auto-scroll'**
  String get autoScrollStart;

  /// No description provided for @autoScrollStop.
  ///
  /// In en, this message translates to:
  /// **'Stop auto-scroll'**
  String get autoScrollStop;

  /// No description provided for @slower.
  ///
  /// In en, this message translates to:
  /// **'Slower'**
  String get slower;

  /// No description provided for @faster.
  ///
  /// In en, this message translates to:
  /// **'Faster'**
  String get faster;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'pages'**
  String get pages;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @finishedLower.
  ///
  /// In en, this message translates to:
  /// **'finished'**
  String get finishedLower;

  /// No description provided for @nextChapter.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextChapter;

  /// No description provided for @previousChapter.
  ///
  /// In en, this message translates to:
  /// **'Previous chapter'**
  String get previousChapter;

  /// No description provided for @releasedOn.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get releasedOn;

  /// No description provided for @continueTo.
  ///
  /// In en, this message translates to:
  /// **'Continue to Chapter'**
  String get continueTo;

  /// No description provided for @latestChapterReached.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest chapter. New chapters will show up in Bookmarks.'**
  String get latestChapterReached;

  /// No description provided for @backToSeries.
  ///
  /// In en, this message translates to:
  /// **'Back to series'**
  String get backToSeries;

  /// No description provided for @builtInExtension.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get builtInExtension;

  /// No description provided for @groupByStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get groupByStatus;

  /// No description provided for @groupByStatusDescription.
  ///
  /// In en, this message translates to:
  /// **'All, updated, completed'**
  String get groupByStatusDescription;

  /// No description provided for @groupBySource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get groupBySource;

  /// No description provided for @groupBySourceDescription.
  ///
  /// In en, this message translates to:
  /// **'One tab per source'**
  String get groupBySourceDescription;

  /// No description provided for @groupByCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get groupByCategory;

  /// No description provided for @groupByCategoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Your own categories'**
  String get groupByCategoryDescription;

  /// No description provided for @groupAndSort.
  ///
  /// In en, this message translates to:
  /// **'Group & sort'**
  String get groupAndSort;

  /// No description provided for @groupTab.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupTab;

  /// No description provided for @sortUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get sortUpdated;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortTitle;

  /// No description provided for @sortChapters.
  ///
  /// In en, this message translates to:
  /// **'Total chapters'**
  String get sortChapters;

  /// No description provided for @sortLatestChapter.
  ///
  /// In en, this message translates to:
  /// **'Latest chapter'**
  String get sortLatestChapter;

  /// No description provided for @sortAdded.
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get sortAdded;

  /// No description provided for @sortLastRead.
  ///
  /// In en, this message translates to:
  /// **'Last read'**
  String get sortLastRead;

  /// No description provided for @sortUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread chapters'**
  String get sortUnread;

  /// No description provided for @sortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewestFirst;

  /// No description provided for @sortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldestFirst;

  /// No description provided for @sortAToZ.
  ///
  /// In en, this message translates to:
  /// **'A to Z'**
  String get sortAToZ;

  /// No description provided for @sortZToA.
  ///
  /// In en, this message translates to:
  /// **'Z to A'**
  String get sortZToA;

  /// No description provided for @sortMostFirst.
  ///
  /// In en, this message translates to:
  /// **'Most first'**
  String get sortMostFirst;

  /// No description provided for @sortFewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Fewest first'**
  String get sortFewestFirst;

  /// No description provided for @sortReverseHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the selected order to reverse it.'**
  String get sortReverseHint;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get manageCategories;

  /// No description provided for @categoriesDescription.
  ///
  /// In en, this message translates to:
  /// **'Long press bookmarks, then the folder button to put them in one.'**
  String get categoriesDescription;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @setCategories.
  ///
  /// In en, this message translates to:
  /// **'Set categories'**
  String get setCategories;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategories;

  /// No description provided for @newCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategoryHint;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @renameCategory.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get deleteCategory;

  /// No description provided for @deleteCategoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Its comics stay bookmarked and keep their other categories.'**
  String get deleteCategoryDescription;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @progressChannel.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressChannel;

  /// No description provided for @updatingBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Updating bookmarks'**
  String get updatingBookmarks;

  /// No description provided for @bookmarksUpdated.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks updated'**
  String get bookmarksUpdated;

  /// No description provided for @haveNewChapters.
  ///
  /// In en, this message translates to:
  /// **'with new chapters'**
  String get haveNewChapters;

  /// No description provided for @changeSource.
  ///
  /// In en, this message translates to:
  /// **'Change source'**
  String get changeSource;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @addSource.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get addSource;

  /// No description provided for @openSource.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openSource;

  /// No description provided for @sourceFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get sourceFrom;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @languagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Each language is its own source'**
  String get languagesDescription;

  /// No description provided for @languagesHint.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks and history are kept per language. Turning one off keeps them; its comics still open.'**
  String get languagesHint;

  /// No description provided for @searchExtensions.
  ///
  /// In en, this message translates to:
  /// **'Search extensions'**
  String get searchExtensions;

  /// No description provided for @allLanguages.
  ///
  /// In en, this message translates to:
  /// **'All languages'**
  String get allLanguages;

  /// No description provided for @hideNsfw.
  ///
  /// In en, this message translates to:
  /// **'Hide 18+'**
  String get hideNsfw;

  /// No description provided for @languageFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Extensions with several languages show under each of them.'**
  String get languageFilterHint;

  /// No description provided for @noMatchingExtensions.
  ///
  /// In en, this message translates to:
  /// **'No extensions match'**
  String get noMatchingExtensions;

  /// No description provided for @noMatchingExtensionsHint.
  ///
  /// In en, this message translates to:
  /// **'Try another name or language.'**
  String get noMatchingExtensionsHint;

  /// No description provided for @comicKeyTooLong.
  ///
  /// In en, this message translates to:
  /// **'This comic\'s link is too long to keep in the library.'**
  String get comicKeyTooLong;

  /// No description provided for @scanlators.
  ///
  /// In en, this message translates to:
  /// **'Scanlators'**
  String get scanlators;

  /// No description provided for @scanlatorsHint.
  ///
  /// In en, this message translates to:
  /// **'Whose version of a chapter shows when several groups have it. Saved on this device.'**
  String get scanlatorsHint;

  /// No description provided for @sourceOrder.
  ///
  /// In en, this message translates to:
  /// **'Source\'s order'**
  String get sourceOrder;

  /// No description provided for @sourceSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get sourceSettings;

  /// No description provided for @sourceSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'The extension\'s own settings. Changes apply to its next request.'**
  String get sourceSettingsHint;

  /// No description provided for @noSourceSettings.
  ///
  /// In en, this message translates to:
  /// **'This source has no settings.'**
  String get noSourceSettings;

  /// No description provided for @openWebView.
  ///
  /// In en, this message translates to:
  /// **'Open in WebView'**
  String get openWebView;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get openInBrowser;

  /// No description provided for @clearCookies.
  ///
  /// In en, this message translates to:
  /// **'Clear cookies'**
  String get clearCookies;

  /// No description provided for @cookiesCleared.
  ///
  /// In en, this message translates to:
  /// **'Cookies cleared'**
  String get cookiesCleared;

  /// No description provided for @pageNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Page didn\'t load'**
  String get pageNotLoaded;

  /// No description provided for @downloadingMihonRuntime.
  ///
  /// In en, this message translates to:
  /// **'Downloading what Mihon extensions need'**
  String get downloadingMihonRuntime;

  /// No description provided for @downloadingMihonBrowser.
  ///
  /// In en, this message translates to:
  /// **'Downloading the browser this extension needs'**
  String get downloadingMihonBrowser;

  /// No description provided for @avifNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This page is an AVIF image, which this device can\'t show'**
  String get avifNotSupported;

  /// No description provided for @verificationNeeded.
  ///
  /// In en, this message translates to:
  /// **'Verification needed'**
  String get verificationNeeded;

  /// No description provided for @verificationNeededHint.
  ///
  /// In en, this message translates to:
  /// **'The site wants to check you are not a bot. Pass the check in the WebView, then close it to try again.'**
  String get verificationNeededHint;

  /// No description provided for @verifyInWebView.
  ///
  /// In en, this message translates to:
  /// **'Verify in WebView'**
  String get verifyInWebView;

  /// No description provided for @sourceConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get sourceConnecting;

  /// No description provided for @sourceOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get sourceOnline;

  /// No description provided for @sourceOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get sourceOffline;

  /// No description provided for @sourceError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get sourceError;

  /// No description provided for @noSourceShort.
  ///
  /// In en, this message translates to:
  /// **'No source installed'**
  String get noSourceShort;

  /// No description provided for @noSourceHint.
  ///
  /// In en, this message translates to:
  /// **'Install a source in Extensions to start reading.'**
  String get noSourceHint;

  /// No description provided for @localComics.
  ///
  /// In en, this message translates to:
  /// **'Local comics'**
  String get localComics;

  /// No description provided for @onThisDevice.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get onThisDevice;

  /// No description provided for @noLocalComics.
  ///
  /// In en, this message translates to:
  /// **'No comics on this device'**
  String get noLocalComics;

  /// No description provided for @noLocalComicsHint.
  ///
  /// In en, this message translates to:
  /// **'Import CBZ or ZIP files, or folders of images, to read them here.'**
  String get noLocalComicsHint;

  /// No description provided for @noLocalComicsHintFiles.
  ///
  /// In en, this message translates to:
  /// **'Import CBZ or ZIP files to read them here.'**
  String get noLocalComicsHintFiles;

  /// No description provided for @importComics.
  ///
  /// In en, this message translates to:
  /// **'Import comics'**
  String get importComics;

  /// No description provided for @importComicsDescription.
  ///
  /// In en, this message translates to:
  /// **'CBZ or ZIP files, or folders of images'**
  String get importComicsDescription;

  /// No description provided for @importComicsDescriptionFiles.
  ///
  /// In en, this message translates to:
  /// **'CBZ or ZIP files'**
  String get importComicsDescriptionFiles;

  /// No description provided for @importFiles.
  ///
  /// In en, this message translates to:
  /// **'CBZ or ZIP files'**
  String get importFiles;

  /// No description provided for @importFolder.
  ///
  /// In en, this message translates to:
  /// **'A folder'**
  String get importFolder;

  /// No description provided for @importFolderHint.
  ///
  /// In en, this message translates to:
  /// **'A folder of images is one chapter; a folder of chapter folders or CBZ files, one series.'**
  String get importFolderHint;

  /// No description provided for @importNamingTitle.
  ///
  /// In en, this message translates to:
  /// **'NAMING FILES'**
  String get importNamingTitle;

  /// No description provided for @importNaming.
  ///
  /// In en, this message translates to:
  /// **'Files with the same series name go into one series, numbered from the name. A ComicInfo.xml inside a CBZ wins over the name.'**
  String get importNaming;

  /// No description provided for @addChapters.
  ///
  /// In en, this message translates to:
  /// **'Add chapters'**
  String get addChapters;

  /// No description provided for @addChaptersHint.
  ///
  /// In en, this message translates to:
  /// **'Every file goes into this comic, whatever it is named. Its number comes from ComicInfo.xml or the name (Ch. 12), else the next one; a chapter with a number it already has is replaced.'**
  String get addChaptersHint;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editDetails;

  /// No description provided for @comicTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get comicTitle;

  /// No description provided for @comicAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get comicAuthor;

  /// No description provided for @comicGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get comicGenres;

  /// No description provided for @comicGenresHint.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated, e.g. Action, Drama'**
  String get comicGenresHint;

  /// No description provided for @coverLabel.
  ///
  /// In en, this message translates to:
  /// **'COVER'**
  String get coverLabel;

  /// No description provided for @chooseCoverImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get chooseCoverImage;

  /// No description provided for @useFirstPage.
  ///
  /// In en, this message translates to:
  /// **'Use first page'**
  String get useFirstPage;

  /// No description provided for @detailsSaved.
  ///
  /// In en, this message translates to:
  /// **'Details saved'**
  String get detailsSaved;

  /// No description provided for @coverChanged.
  ///
  /// In en, this message translates to:
  /// **'Cover changed'**
  String get coverChanged;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the changes'**
  String get saveFailed;

  /// No description provided for @importingComics.
  ///
  /// In en, this message translates to:
  /// **'Importing comics…'**
  String get importingComics;

  /// No description provided for @importBusy.
  ///
  /// In en, this message translates to:
  /// **'An import is still running'**
  String get importBusy;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import the comics'**
  String get importFailed;

  /// No description provided for @importNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing was imported'**
  String get importNothing;

  /// No description provided for @deleteFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Delete from device'**
  String get deleteFromDevice;

  /// No description provided for @deleteLocalComicMessage.
  ///
  /// In en, this message translates to:
  /// **'Removes the imported files of this comic from the device. Its bookmark and history stay.'**
  String get deleteLocalComicMessage;

  /// No description provided for @localComicDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted from device'**
  String get localComicDeleted;

  /// No description provided for @extensions.
  ///
  /// In en, this message translates to:
  /// **'Extensions'**
  String get extensions;

  /// No description provided for @extensionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Sources to read comics from'**
  String get extensionsDescription;

  /// No description provided for @installed.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installed;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @installing.
  ///
  /// In en, this message translates to:
  /// **'Installing…'**
  String get installing;

  /// No description provided for @sourceNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'is not installed'**
  String get sourceNotInstalled;

  /// No description provided for @sourceLooking.
  ///
  /// In en, this message translates to:
  /// **'Looking for it in your repos…'**
  String get sourceLooking;

  /// No description provided for @sourceInstallHint.
  ///
  /// In en, this message translates to:
  /// **'Install the extension to open this comic.'**
  String get sourceInstallHint;

  /// No description provided for @sourceNotInRepos.
  ///
  /// In en, this message translates to:
  /// **'None of your repos has this source. Add its repo in Extensions.'**
  String get sourceNotInRepos;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// No description provided for @uninstallDescription.
  ///
  /// In en, this message translates to:
  /// **'Its bookmarks and reading history stay, but can only be opened again after reinstalling the extension.'**
  String get uninstallDescription;

  /// No description provided for @extensionInstalled.
  ///
  /// In en, this message translates to:
  /// **'installed'**
  String get extensionInstalled;

  /// No description provided for @extensionUpdated.
  ///
  /// In en, this message translates to:
  /// **'updated'**
  String get extensionUpdated;

  /// No description provided for @needsAppUpdate.
  ///
  /// In en, this message translates to:
  /// **'Needs app update'**
  String get needsAppUpdate;

  /// No description provided for @noExtensionsHint.
  ///
  /// In en, this message translates to:
  /// **'Install an extension to browse and read comics.'**
  String get noExtensionsHint;

  /// No description provided for @noAvailableExtensions.
  ///
  /// In en, this message translates to:
  /// **'Nothing new to install'**
  String get noAvailableExtensions;

  /// No description provided for @noAvailableExtensionsHint.
  ///
  /// In en, this message translates to:
  /// **'Every extension from your repos is installed. Add a repo for more.'**
  String get noAvailableExtensionsHint;

  /// No description provided for @manageRepos.
  ///
  /// In en, this message translates to:
  /// **'Extension repos'**
  String get manageRepos;

  /// No description provided for @reposDescription.
  ///
  /// In en, this message translates to:
  /// **'Where extensions are listed from'**
  String get reposDescription;

  /// No description provided for @addRepo.
  ///
  /// In en, this message translates to:
  /// **'Add repo'**
  String get addRepo;

  /// No description provided for @repoAdding.
  ///
  /// In en, this message translates to:
  /// **'Checking repo…'**
  String get repoAdding;

  /// No description provided for @repoInvalid.
  ///
  /// In en, this message translates to:
  /// **'Not a valid extension repo URL'**
  String get repoInvalid;

  /// No description provided for @repoFailed.
  ///
  /// In en, this message translates to:
  /// **'Repo unavailable'**
  String get repoFailed;

  /// No description provided for @mihonRepoUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Mihon repos need Android 9+, Windows, macOS or Linux'**
  String get mihonRepoUnsupported;

  /// No description provided for @mihonRepoUnsupportedStore.
  ///
  /// In en, this message translates to:
  /// **'Mihon repos (index.min.json, index.pb) are not supported in this version. Add a Yoru repo (…/index.json).'**
  String get mihonRepoUnsupportedStore;

  /// No description provided for @mihonRepoUnsupportedIos.
  ///
  /// In en, this message translates to:
  /// **'Mihon repos (index.min.json, index.pb) don\'t work on iOS. Add a Yoru repo (…/index.json).'**
  String get mihonRepoUnsupportedIos;

  /// No description provided for @repoWarning.
  ///
  /// In en, this message translates to:
  /// **'Extensions run code and access the internet. Only add repos you trust.'**
  String get repoWarning;

  /// No description provided for @noFilters.
  ///
  /// In en, this message translates to:
  /// **'This source has no filters.'**
  String get noFilters;

  /// No description provided for @duplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Already in your library'**
  String get duplicateTitle;

  /// No description provided for @duplicateMessagePrefix.
  ///
  /// In en, this message translates to:
  /// **'You bookmarked this series from'**
  String get duplicateMessagePrefix;

  /// No description provided for @duplicateMessage.
  ///
  /// In en, this message translates to:
  /// **'Migrate moves that bookmark and its reading history here. Merge keeps one entry that reads chapters from both sources. Add anyway keeps both as separate entries.'**
  String get duplicateMessage;

  /// No description provided for @mergeSources.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get mergeSources;

  /// No description provided for @merged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get merged;

  /// No description provided for @mergedSources.
  ///
  /// In en, this message translates to:
  /// **'Merged sources'**
  String get mergedSources;

  /// No description provided for @mergedSourcesHint.
  ///
  /// In en, this message translates to:
  /// **'Each chapter comes from the first source that has it; title, cover and info from the first. Drag to reorder.'**
  String get mergedSourcesHint;

  /// No description provided for @noOtherSourceToMerge.
  ///
  /// In en, this message translates to:
  /// **'Install another source to merge with.'**
  String get noOtherSourceToMerge;

  /// No description provided for @mergeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search this series in another source'**
  String get mergeSearchHint;

  /// No description provided for @allSources.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get allSources;

  /// No description provided for @chapterSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get chapterSources;

  /// No description provided for @chapterSourcesHint.
  ///
  /// In en, this message translates to:
  /// **'Show the chapters taken from one source.'**
  String get chapterSourcesHint;

  /// No description provided for @dedupeChapters.
  ///
  /// In en, this message translates to:
  /// **'Deduplicate chapters'**
  String get dedupeChapters;

  /// No description provided for @dedupeChaptersHint.
  ///
  /// In en, this message translates to:
  /// **'One chapter per number, from the first source that has it'**
  String get dedupeChaptersHint;

  /// No description provided for @migrate.
  ///
  /// In en, this message translates to:
  /// **'Migrate'**
  String get migrate;

  /// No description provided for @addAnyway.
  ///
  /// In en, this message translates to:
  /// **'Add anyway'**
  String get addAnyway;

  /// No description provided for @viewBookmarkedSeries.
  ///
  /// In en, this message translates to:
  /// **'View bookmarked series'**
  String get viewBookmarkedSeries;

  /// No description provided for @migrated.
  ///
  /// In en, this message translates to:
  /// **'Migrated to this source'**
  String get migrated;

  /// No description provided for @stopRefresh.
  ///
  /// In en, this message translates to:
  /// **'Stop updating bookmarks'**
  String get stopRefresh;

  /// No description provided for @importFromApps.
  ///
  /// In en, this message translates to:
  /// **'Import from other apps'**
  String get importFromApps;

  /// No description provided for @importFromAppsDescription.
  ///
  /// In en, this message translates to:
  /// **'Mihon, Tachiyomi or Comix.to'**
  String get importFromAppsDescription;

  /// No description provided for @migrateSource.
  ///
  /// In en, this message translates to:
  /// **'Migrate source'**
  String get migrateSource;

  /// No description provided for @migrateSourceDescription.
  ///
  /// In en, this message translates to:
  /// **'Move bookmarks and reading history to another source'**
  String get migrateSourceDescription;

  /// No description provided for @dnsOverHttps.
  ///
  /// In en, this message translates to:
  /// **'DNS over HTTPS'**
  String get dnsOverHttps;

  /// No description provided for @dnsOverHttpsDescription.
  ///
  /// In en, this message translates to:
  /// **'Reach sites your network’s DNS blocks'**
  String get dnsOverHttpsDescription;

  /// No description provided for @dnsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get dnsOff;

  /// No description provided for @dnsOffDescription.
  ///
  /// In en, this message translates to:
  /// **'Use the network’s DNS'**
  String get dnsOffDescription;

  /// No description provided for @dnsCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get dnsCustom;

  /// No description provided for @dnsCustomDescription.
  ///
  /// In en, this message translates to:
  /// **'Your own DoH server'**
  String get dnsCustomDescription;

  /// No description provided for @dnsCustomInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a server address (https only, not http)'**
  String get dnsCustomInvalid;

  /// No description provided for @dnsUseCustom.
  ///
  /// In en, this message translates to:
  /// **'Use this server'**
  String get dnsUseCustom;

  /// No description provided for @dnsCoverageAndroid.
  ///
  /// In en, this message translates to:
  /// **'On Android this covers Mihon extensions and web views. JS extensions and images use it for sites the network’s DNS blocks.'**
  String get dnsCoverageAndroid;

  /// No description provided for @dnsCoverageDesktop.
  ///
  /// In en, this message translates to:
  /// **'Covers extensions, images, downloads and web views.'**
  String get dnsCoverageDesktop;

  /// No description provided for @dnsPrivateDnsHint.
  ///
  /// In en, this message translates to:
  /// **'For the whole phone, set Private DNS in Android’s network settings (e.g. one.one.one.one).'**
  String get dnsPrivateDnsHint;

  /// No description provided for @importMihon.
  ///
  /// In en, this message translates to:
  /// **'Import from Mihon / Tachiyomi'**
  String get importMihon;

  /// No description provided for @importMihonDescription.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks from a .tachibk backup'**
  String get importMihonDescription;

  /// No description provided for @importComix.
  ///
  /// In en, this message translates to:
  /// **'Import from Comix.to'**
  String get importComix;

  /// No description provided for @importComixDescription.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks and read chapters from a .csv export'**
  String get importComixDescription;

  /// No description provided for @migrateFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get migrateFrom;

  /// No description provided for @migrateTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get migrateTo;

  /// No description provided for @migrateToOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Searched in this order: a comic not found in one is looked up in the next. Drag to reorder.'**
  String get migrateToOrderHint;

  /// No description provided for @removeSource.
  ///
  /// In en, this message translates to:
  /// **'Remove source'**
  String get removeSource;

  /// No description provided for @importComixTo.
  ///
  /// In en, this message translates to:
  /// **'Search the titles in'**
  String get importComixTo;

  /// No description provided for @pickSource.
  ///
  /// In en, this message translates to:
  /// **'Pick a source'**
  String get pickSource;

  /// No description provided for @noBookmarksToMigrate.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks to migrate'**
  String get noBookmarksToMigrate;

  /// No description provided for @noBookmarksToMigrateHint.
  ///
  /// In en, this message translates to:
  /// **'Bookmark comics first, then move them here.'**
  String get noBookmarksToMigrateHint;

  /// No description provided for @noOtherSource.
  ///
  /// In en, this message translates to:
  /// **'Install another source to migrate to.'**
  String get noOtherSource;

  /// No description provided for @findMatches.
  ///
  /// In en, this message translates to:
  /// **'Find matches'**
  String get findMatches;

  /// No description provided for @selectNone.
  ///
  /// In en, this message translates to:
  /// **'Select none'**
  String get selectNone;

  /// No description provided for @matchSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get matchSearching;

  /// No description provided for @matchWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get matchWaiting;

  /// No description provided for @matchNotFound.
  ///
  /// In en, this message translates to:
  /// **'No match. Tap to search.'**
  String get matchNotFound;

  /// No description provided for @matchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Tap to retry.'**
  String get matchFailed;

  /// No description provided for @matchSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get matchSkipped;

  /// No description provided for @matchMigrated.
  ///
  /// In en, this message translates to:
  /// **'Migrated'**
  String get matchMigrated;

  /// No description provided for @matchMigrateFailed.
  ///
  /// In en, this message translates to:
  /// **'Migration failed'**
  String get matchMigrateFailed;

  /// No description provided for @matchesFound.
  ///
  /// In en, this message translates to:
  /// **'found'**
  String get matchesFound;

  /// No description provided for @searchingSlowly.
  ///
  /// In en, this message translates to:
  /// **'Comics are searched one at a time, a few seconds apart, so the site does not block you.'**
  String get searchingSlowly;

  /// No description provided for @pickMatch.
  ///
  /// In en, this message translates to:
  /// **'Pick the match'**
  String get pickMatch;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @migrateCount.
  ///
  /// In en, this message translates to:
  /// **'Migrate'**
  String get migrateCount;

  /// No description provided for @importCount.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importCount;

  /// No description provided for @migrating.
  ///
  /// In en, this message translates to:
  /// **'Migrating…'**
  String get migrating;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get importing;

  /// No description provided for @migrationDone.
  ///
  /// In en, this message translates to:
  /// **'Migration done'**
  String get migrationDone;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Import done'**
  String get importDone;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'added'**
  String get added;

  /// No description provided for @alreadyInLibrary.
  ///
  /// In en, this message translates to:
  /// **'already in your library'**
  String get alreadyInLibrary;

  /// No description provided for @sameTitleElsewhere.
  ///
  /// In en, this message translates to:
  /// **'bookmarked from another source'**
  String get sameTitleElsewhere;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get failed;

  /// No description provided for @importLoadHint.
  ///
  /// In en, this message translates to:
  /// **'Covers and chapters load when you open a comic, or pull to refresh in Bookmarks.'**
  String get importLoadHint;

  /// No description provided for @chaptersMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'chapters marked read'**
  String get chaptersMarkedRead;

  /// No description provided for @mihonLoadHint.
  ///
  /// In en, this message translates to:
  /// **'Covers load when you open a comic, or pull to refresh in Bookmarks.'**
  String get mihonLoadHint;

  /// No description provided for @readTo.
  ///
  /// In en, this message translates to:
  /// **'Read to ch.'**
  String get readTo;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get chooseFile;

  /// No description provided for @readingFile.
  ///
  /// In en, this message translates to:
  /// **'Reading file…'**
  String get readingFile;

  /// No description provided for @mihonHint.
  ///
  /// In en, this message translates to:
  /// **'In Mihon, open More → Backup and restore → Create backup, then pick the .tachibk file here. Only bookmarked comics from sources Yoru has are imported, with their categories and read chapters. Run it again to bring read chapters to comics imported before.'**
  String get mihonHint;

  /// No description provided for @notAvailableHere.
  ///
  /// In en, this message translates to:
  /// **'Not available here'**
  String get notAvailableHere;

  /// No description provided for @unreadableLinks.
  ///
  /// In en, this message translates to:
  /// **'unreadable links'**
  String get unreadableLinks;

  /// No description provided for @needsInstall.
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get needsInstall;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get appLanguage;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get noConnection;

  /// No description provided for @noConnectionHint.
  ///
  /// In en, this message translates to:
  /// **'Check your internet, then try again.'**
  String get noConnectionHint;

  /// No description provided for @comicReaderApp.
  ///
  /// In en, this message translates to:
  /// **'COMIC READER APP'**
  String get comicReaderApp;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'FROM'**
  String get from;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @newShort.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get newShort;

  /// No description provided for @importNamingExamples.
  ///
  /// In en, this message translates to:
  /// **'Blue Box - Ch. 12.cbz\nBlue Box Chapter 12.5.cbz\nMonster Vol. 3.cbz'**
  String get importNamingExamples;

  /// No description provided for @repoHint.
  ///
  /// In en, this message translates to:
  /// **'https://…/index.json · index.min.json · index.pb'**
  String get repoHint;

  /// No description provided for @repoHintIos.
  ///
  /// In en, this message translates to:
  /// **'https://…/index.json'**
  String get repoHintIos;

  /// No description provided for @dnsCustomHint.
  ///
  /// In en, this message translates to:
  /// **'dns.example.com or https://…/dns-query'**
  String get dnsCustomHint;

  /// A chapter by its number, e.g. "Chapter 12".
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String chapterNumber(String number);

  /// No description provided for @comicCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comic} other{{count} comics}}'**
  String comicCount(int count);

  /// No description provided for @chapterCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Chapter} other{{count} Chapters}}'**
  String chapterCount(int count);

  /// No description provided for @chapterCountLower.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chapter} other{{count} chapters}}'**
  String chapterCountLower(int count);

  /// No description provided for @sourceCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 source} other{{count} sources}}'**
  String sourceCount(int count);

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect to {host}. Your network may be blocking it; try again, or use a VPN or another network.'**
  String connectionFailed(String host);

  /// No description provided for @imported.
  ///
  /// In en, this message translates to:
  /// **'Imported {chapters} {chapters, plural, =1{chapter} other{chapters}} into {series} series'**
  String imported(int chapters, int series);

  /// No description provided for @importSkipped.
  ///
  /// In en, this message translates to:
  /// **'{files, plural, =1{1 file skipped} other{{files} files skipped}}'**
  String importSkipped(int files);

  /// Short month names, January to December, separated by commas.
  ///
  /// In en, this message translates to:
  /// **'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec'**
  String get monthsShort;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String minutesAgo(int n);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String hoursAgo(int n);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day ago} other{{n} days ago}}'**
  String daysAgo(int n);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String minutesShort(int n);

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'{n} h'**
  String hoursShort(int n);

  /// No description provided for @daysShort.
  ///
  /// In en, this message translates to:
  /// **'{n} d'**
  String daysShort(int n);

  /// No description provided for @translatePages.
  ///
  /// In en, this message translates to:
  /// **'Translate pages'**
  String get translatePages;

  /// No description provided for @translatePagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Lay a translation over each page with an AI model'**
  String get translatePagesDescription;

  /// No description provided for @translateNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set up'**
  String get translateNotSet;

  /// No description provided for @translateServer.
  ///
  /// In en, this message translates to:
  /// **'Server (OpenAI-compatible)'**
  String get translateServer;

  /// No description provided for @translateApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get translateApiKey;

  /// No description provided for @translateApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Empty for Ollama or LM Studio'**
  String get translateApiKeyHint;

  /// No description provided for @translateShowKey.
  ///
  /// In en, this message translates to:
  /// **'Show key'**
  String get translateShowKey;

  /// No description provided for @translateModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get translateModel;

  /// No description provided for @translateModelHint.
  ///
  /// In en, this message translates to:
  /// **'Any chat model'**
  String get translateModelHint;

  /// No description provided for @translateLanguage.
  ///
  /// In en, this message translates to:
  /// **'Translate into'**
  String get translateLanguage;

  /// No description provided for @translateMissing.
  ///
  /// In en, this message translates to:
  /// **'Set both a server and a model, or leave both empty'**
  String get translateMissing;

  /// No description provided for @translatePrivacy.
  ///
  /// In en, this message translates to:
  /// **'The text of pages you read is sent to this server to be translated; the images stay on this device. The key stays on this device and is not in backups or sync. Translations are kept in the cache, so a page is translated once.'**
  String get translatePrivacy;

  /// No description provided for @translating.
  ///
  /// In en, this message translates to:
  /// **'Translating'**
  String get translating;

  /// No description provided for @translateFailed.
  ///
  /// In en, this message translates to:
  /// **'Not translated · retry'**
  String get translateFailed;

  /// No description provided for @showOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show original'**
  String get showOriginal;

  /// No description provided for @translateAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get translateAppLanguage;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @translateLettering.
  ///
  /// In en, this message translates to:
  /// **'Lettering'**
  String get translateLettering;

  /// No description provided for @translateUppercase.
  ///
  /// In en, this message translates to:
  /// **'All caps'**
  String get translateUppercase;

  /// No description provided for @translateUppercaseHint.
  ///
  /// In en, this message translates to:
  /// **'Capital letters, like comic lettering'**
  String get translateUppercaseHint;

  /// No description provided for @translateFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get translateFont;

  /// No description provided for @translateFontHint.
  ///
  /// In en, this message translates to:
  /// **'Import a .ttf or .otf you have a licence for'**
  String get translateFontHint;

  /// No description provided for @translateFontInvalid.
  ///
  /// In en, this message translates to:
  /// **'Not a .ttf or .otf font'**
  String get translateFontInvalid;

  /// No description provided for @translateFontImport.
  ///
  /// In en, this message translates to:
  /// **'Import…'**
  String get translateFontImport;

  /// No description provided for @translateScript.
  ///
  /// In en, this message translates to:
  /// **'Text in pages'**
  String get translateScript;

  /// No description provided for @translateScriptCjk.
  ///
  /// In en, this message translates to:
  /// **'Japanese · Chinese · English'**
  String get translateScriptCjk;

  /// No description provided for @translateScriptKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get translateScriptKorean;

  /// No description provided for @translateScriptLatin.
  ///
  /// In en, this message translates to:
  /// **'Other Latin letters'**
  String get translateScriptLatin;

  /// No description provided for @translateScriptHint.
  ///
  /// In en, this message translates to:
  /// **'Read on this device. Auto goes by the source\'s language. Its reading model (about 25 MB) is downloaded the first time.'**
  String get translateScriptHint;

  /// No description provided for @translateNotes.
  ///
  /// In en, this message translates to:
  /// **'Translation notes'**
  String get translateNotes;

  /// No description provided for @translateNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional, e.g. keep attack names in English'**
  String get translateNotesHint;

  /// No description provided for @showTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get showTranslation;

  /// No description provided for @translateScriptAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get translateScriptAuto;

  /// No description provided for @translateEngine.
  ///
  /// In en, this message translates to:
  /// **'Translated by'**
  String get translateEngine;

  /// No description provided for @translateEngineServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get translateEngineServer;

  /// No description provided for @translateMlKitHint.
  ///
  /// In en, this message translates to:
  /// **'Google\'s offline translation: fast, free and light, but plainer than an AI model; it cannot fix misread text or follow notes. Its language packs (about 30 MB each) download the first time. The comic\'s language comes from its source.'**
  String get translateMlKitHint;

  /// No description provided for @translateScriptEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get translateScriptEnglish;

  /// No description provided for @translateCustomServer.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get translateCustomServer;

  /// No description provided for @translateTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get translateTest;

  /// No description provided for @translateTestOk.
  ///
  /// In en, this message translates to:
  /// **'Replied in {ms} ms: “{reply}”'**
  String translateTestOk(int ms, String reply);

  /// No description provided for @translateErrorConnection.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server: check the URL and your connection'**
  String get translateErrorConnection;

  /// No description provided for @translateErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to answer'**
  String get translateErrorTimeout;

  /// No description provided for @translateErrorCertificate.
  ///
  /// In en, this message translates to:
  /// **'The server\'s security certificate isn\'t valid'**
  String get translateErrorCertificate;

  /// No description provided for @translateErrorCancelled.
  ///
  /// In en, this message translates to:
  /// **'The request was stopped'**
  String get translateErrorCancelled;

  /// No description provided for @translateErrorKey.
  ///
  /// In en, this message translates to:
  /// **'The API key was refused: check it, and that it may use this model'**
  String get translateErrorKey;

  /// No description provided for @translateErrorPayment.
  ///
  /// In en, this message translates to:
  /// **'The account needs credit or a paid plan'**
  String get translateErrorPayment;

  /// No description provided for @translateErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found: check the URL and the model name'**
  String get translateErrorNotFound;

  /// No description provided for @translateErrorTooLong.
  ///
  /// In en, this message translates to:
  /// **'The page\'s text is too long for this server'**
  String get translateErrorTooLong;

  /// No description provided for @translateErrorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many requests, or the free quota is used up: wait a moment, or check your plan'**
  String get translateErrorRateLimit;

  /// No description provided for @translateErrorServer.
  ///
  /// In en, this message translates to:
  /// **'The server has a problem: try again later'**
  String get translateErrorServer;

  /// No description provided for @translateErrorRefused.
  ///
  /// In en, this message translates to:
  /// **'The server refused the request'**
  String get translateErrorRefused;

  /// No description provided for @translateChapterAgain.
  ///
  /// In en, this message translates to:
  /// **'Translate chapter again'**
  String get translateChapterAgain;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
