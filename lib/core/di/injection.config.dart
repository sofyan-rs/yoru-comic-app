// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:hive_ce/hive.dart' as _i738;
import 'package:injectable/injectable.dart' as _i526;
import 'package:yoru/core/data/datasources/series_remote_data_source.dart'
    as _i474;
import 'package:yoru/core/di/register_module.dart' as _i1041;
import 'package:yoru/core/network/api_client.dart' as _i345;
import 'package:yoru/core/network/network_info.dart' as _i761;
import 'package:yoru/core/notifications/progress_notifier.dart' as _i675;
import 'package:yoru/core/source/extension_bridge.dart' as _i547;
import 'package:yoru/core/source/extension_manager.dart' as _i669;
import 'package:yoru/core/storage/hive_boxes.dart' as _i671;
import 'package:yoru/core/storage/library_journal.dart' as _i1050;
import 'package:yoru/core/utils/clock.dart' as _i220;
import 'package:yoru/features/backup/data/datasources/backup_file_data_source.dart'
    as _i339;
import 'package:yoru/features/backup/data/repositories/backup_repository_impl.dart'
    as _i803;
import 'package:yoru/features/backup/domain/repositories/backup_repository.dart'
    as _i261;
import 'package:yoru/features/backup/domain/usecases/backup_library.dart'
    as _i618;
import 'package:yoru/features/backup/presentation/bloc/backup_cubit.dart'
    as _i151;
import 'package:yoru/features/bookmark/data/datasources/bookmark_local_data_source.dart'
    as _i308;
import 'package:yoru/features/bookmark/data/repositories/bookmark_repository_impl.dart'
    as _i299;
import 'package:yoru/features/bookmark/domain/repositories/bookmark_repository.dart'
    as _i614;
import 'package:yoru/features/bookmark/domain/usecases/bookmark_usecases.dart'
    as _i934;
import 'package:yoru/features/bookmark/domain/usecases/merge_sources.dart'
    as _i814;
import 'package:yoru/features/bookmark/domain/usecases/migrate_comic.dart'
    as _i1023;
import 'package:yoru/features/bookmark/domain/usecases/refresh_bookmark.dart'
    as _i708;
import 'package:yoru/features/bookmark/presentation/bloc/bookmark_cubit.dart'
    as _i527;
import 'package:yoru/features/category/data/datasources/category_local_data_source.dart'
    as _i349;
import 'package:yoru/features/category/data/repositories/category_repository_impl.dart'
    as _i819;
import 'package:yoru/features/category/domain/repositories/category_repository.dart'
    as _i136;
import 'package:yoru/features/category/domain/usecases/category_usecases.dart'
    as _i216;
import 'package:yoru/features/category/presentation/bloc/category_cubit.dart'
    as _i277;
import 'package:yoru/features/comic_detail/data/repositories/comic_detail_repository_impl.dart'
    as _i231;
import 'package:yoru/features/comic_detail/domain/repositories/comic_detail_repository.dart'
    as _i609;
import 'package:yoru/features/comic_detail/domain/usecases/get_comic_details.dart'
    as _i784;
import 'package:yoru/features/comic_detail/presentation/bloc/comic_details_bloc.dart'
    as _i48;
import 'package:yoru/features/download/data/datasources/download_file_data_source.dart'
    as _i736;
import 'package:yoru/features/download/data/datasources/download_local_data_source.dart'
    as _i697;
import 'package:yoru/features/download/data/datasources/page_download_queue.dart'
    as _i917;
import 'package:yoru/features/download/data/repositories/download_repository_impl.dart'
    as _i461;
import 'package:yoru/features/download/domain/repositories/download_repository.dart'
    as _i1026;
import 'package:yoru/features/download/domain/usecases/download_usecases.dart'
    as _i183;
import 'package:yoru/features/download/presentation/bloc/download_cubit.dart'
    as _i641;
import 'package:yoru/features/explore/data/repositories/explore_repository_impl.dart'
    as _i521;
import 'package:yoru/features/explore/domain/repositories/explore_repository.dart'
    as _i331;
import 'package:yoru/features/explore/domain/usecases/explore_comics.dart'
    as _i783;
import 'package:yoru/features/explore/presentation/bloc/explore_bloc.dart'
    as _i47;
import 'package:yoru/features/explore/presentation/bloc/filter_cubit.dart'
    as _i583;
import 'package:yoru/features/history/data/datasources/history_local_data_source.dart'
    as _i326;
import 'package:yoru/features/history/data/repositories/history_repository_impl.dart'
    as _i942;
import 'package:yoru/features/history/domain/repositories/history_repository.dart'
    as _i328;
import 'package:yoru/features/history/domain/usecases/history_usecases.dart'
    as _i553;
import 'package:yoru/features/history/presentation/bloc/history_cubit.dart'
    as _i309;
import 'package:yoru/features/home/data/repositories/home_repository_impl.dart'
    as _i782;
import 'package:yoru/features/home/domain/repositories/home_repository.dart'
    as _i766;
import 'package:yoru/features/home/domain/usecases/get_home.dart' as _i107;
import 'package:yoru/features/home/presentation/bloc/home_bloc.dart' as _i657;
import 'package:yoru/features/latest/data/repositories/latest_repository_impl.dart'
    as _i175;
import 'package:yoru/features/latest/domain/repositories/latest_repository.dart'
    as _i478;
import 'package:yoru/features/latest/domain/usecases/get_latest_comics.dart'
    as _i116;
import 'package:yoru/features/latest/presentation/bloc/latest_bloc.dart'
    as _i307;
import 'package:yoru/features/migration/data/datasources/migration_file_data_source.dart'
    as _i168;
import 'package:yoru/features/migration/data/repositories/migration_file_repository_impl.dart'
    as _i387;
import 'package:yoru/features/migration/data/repositories/pending_read_repository_impl.dart'
    as _i746;
import 'package:yoru/features/migration/domain/repositories/migration_file_repository.dart'
    as _i89;
import 'package:yoru/features/migration/domain/repositories/pending_read_repository.dart'
    as _i70;
import 'package:yoru/features/migration/domain/usecases/apply_pending_reads.dart'
    as _i364;
import 'package:yoru/features/migration/domain/usecases/import_library.dart'
    as _i1054;
import 'package:yoru/features/migration/domain/usecases/pick_files.dart'
    as _i905;
import 'package:yoru/features/migration/domain/usecases/source_migration.dart'
    as _i206;
import 'package:yoru/features/migration/presentation/bloc/match_cubit.dart'
    as _i896;
import 'package:yoru/features/migration/presentation/bloc/mihon_import_cubit.dart'
    as _i140;
import 'package:yoru/features/reader/data/repositories/reader_repository_impl.dart'
    as _i380;
import 'package:yoru/features/reader/domain/repositories/reader_repository.dart'
    as _i401;
import 'package:yoru/features/reader/domain/usecases/get_chapter_content.dart'
    as _i865;
import 'package:yoru/features/reader/presentation/bloc/reader_bloc.dart'
    as _i399;
import 'package:yoru/features/settings/data/datasources/settings_local_data_source.dart'
    as _i480;
import 'package:yoru/features/settings/data/repositories/settings_repository_impl.dart'
    as _i918;
import 'package:yoru/features/settings/domain/repositories/settings_repository.dart'
    as _i87;
import 'package:yoru/features/settings/domain/usecases/settings_usecases.dart'
    as _i730;
import 'package:yoru/features/settings/presentation/bloc/settings_cubit.dart'
    as _i625;
import 'package:yoru/features/source/presentation/bloc/extensions_cubit.dart'
    as _i576;
import 'package:yoru/features/source/presentation/bloc/sources_cubit.dart'
    as _i165;
import 'package:yoru/features/sync/data/datasources/drive_data_source.dart'
    as _i696;
import 'package:yoru/features/sync/data/datasources/google_auth_data_source.dart'
    as _i193;
import 'package:yoru/features/sync/data/repositories/sync_repository_impl.dart'
    as _i735;
import 'package:yoru/features/sync/domain/repositories/sync_repository.dart'
    as _i600;
import 'package:yoru/features/sync/domain/usecases/migrate_library.dart'
    as _i602;
import 'package:yoru/features/sync/domain/usecases/sync_usecases.dart'
    as _i1020;
import 'package:yoru/features/sync/presentation/bloc/sync_cubit.dart' as _i3;
import 'package:yoru/features/translate/data/datasources/llm_translator.dart'
    as _i568;
import 'package:yoru/features/translate/data/datasources/translation_cache.dart'
    as _i701;
import 'package:yoru/features/translate/data/repositories/translation_repository_impl.dart'
    as _i1064;
import 'package:yoru/features/translate/domain/repositories/translation_repository.dart'
    as _i509;
import 'package:yoru/features/translate/domain/usecases/translate_page.dart'
    as _i296;
import 'package:yoru/features/update/data/datasources/app_installer.dart'
    as _i850;
import 'package:yoru/features/update/data/datasources/update_remote_data_source.dart'
    as _i61;
import 'package:yoru/features/update/data/repositories/update_repository_impl.dart'
    as _i747;
import 'package:yoru/features/update/domain/repositories/update_repository.dart'
    as _i757;
import 'package:yoru/features/update/domain/usecases/update_usecases.dart'
    as _i928;
import 'package:yoru/features/update/presentation/bloc/update_cubit.dart'
    as _i715;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    final storageModule = _$StorageModule();
    final appInstallerModule = _$AppInstallerModule();
    final googleAuthModule = _$GoogleAuthModule();
    gh.factory<_i583.FilterCubit>(() => _i583.FilterCubit());
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i738.HiveInterface>(() => registerModule.hive);
    gh.lazySingleton<_i220.Clock>(() => _i220.Clock());
    gh.lazySingleton<_i675.ProgressNotifier>(
      () => _i675.LocalProgressNotifier(),
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.extensionStorageBox,
      instanceName: 'extension_storage',
      preResolve: true,
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.categoriesBox,
      instanceName: 'categories',
      preResolve: true,
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.pendingReadsBox,
      instanceName: 'pending_reads',
      preResolve: true,
    );
    gh.factory<_i602.MigrateSnapshot>(
      () => _i602.MigrateSnapshot(gh<_i220.Clock>()),
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.downloadsBox,
      instanceName: 'downloads',
      preResolve: true,
    );
    gh.lazySingleton<_i339.BackupFileDataSource>(
      () => _i339.BackupFileDataSourceImpl(),
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.historyComicsBox,
      instanceName: 'history_comics',
      preResolve: true,
    );
    gh.lazySingleton<_i261.BackupRepository>(
      () => _i803.BackupRepositoryImpl(
        gh<_i339.BackupFileDataSource>(),
        gh<_i220.Clock>(),
      ),
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.historyEntriesBox,
      instanceName: 'history_entries',
      preResolve: true,
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.downloadComicsBox,
      instanceName: 'download_comics',
      preResolve: true,
    );
    gh.lazySingleton<_i547.ExtensionBridge>(
      () => _i547.ExtensionBridge(
        gh<_i738.Box<String>>(instanceName: 'extension_storage'),
      ),
    );
    gh.lazySingleton<_i168.MigrationFileDataSource>(
      () => _i168.MigrationFileDataSourceImpl(),
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.bookmarksBox,
      instanceName: 'bookmarks',
      preResolve: true,
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.settingsBox,
      instanceName: 'settings',
      preResolve: true,
    );
    gh.lazySingleton<_i326.HistoryLocalDataSource>(
      () => _i326.HistoryLocalDataSourceImpl(
        gh<_i738.Box<String>>(instanceName: 'history_entries'),
        gh<_i738.Box<String>>(instanceName: 'history_comics'),
      ),
    );
    gh.lazySingleton<_i701.TranslationCache>(
      () => _i701.TranslationCacheImpl(),
    );
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.fileDio,
      instanceName: 'files_dio',
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.libraryDeletionsBox,
      instanceName: 'library_deletions',
      preResolve: true,
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.extensionsBox,
      instanceName: 'extensions',
      preResolve: true,
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.comicCategoriesBox,
      instanceName: 'comic_categories',
      preResolve: true,
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.sourceSettingsBox,
      instanceName: 'source_settings',
      preResolve: true,
    );
    await gh.factoryAsync<_i738.Box<String>>(
      () => storageModule.syncBox,
      instanceName: 'sync',
      preResolve: true,
    );
    gh.lazySingleton<_i736.DownloadFileDataSource>(
      () => _i736.DownloadFileDataSourceImpl(),
    );
    gh.lazySingleton<_i850.AppInstaller>(
      () => appInstallerModule.installer(
        gh<_i361.Dio>(instanceName: 'files_dio'),
      ),
    );
    gh.lazySingleton<_i70.PendingReadRepository>(
      () => _i746.PendingReadRepositoryImpl(
        gh<_i738.Box<String>>(instanceName: 'pending_reads'),
      ),
    );
    gh.lazySingleton<_i349.CategoryLocalDataSource>(
      () => _i349.CategoryLocalDataSourceImpl(
        gh<_i738.Box<String>>(instanceName: 'categories'),
        gh<_i738.Box<String>>(instanceName: 'comic_categories'),
      ),
    );
    gh.lazySingleton<_i568.LlmTranslator>(
      () => _i568.LlmTranslatorImpl(gh<_i361.Dio>(instanceName: 'files_dio')),
    );
    gh.lazySingleton<_i761.NetworkInfo>(
      () => _i761.NetworkInfoImpl(gh<_i895.Connectivity>()),
    );
    gh.lazySingleton<_i193.GoogleAuthDataSource>(
      () => googleAuthModule.googleAuth(
        gh<_i738.Box<String>>(instanceName: 'sync'),
      ),
    );
    gh.lazySingleton<_i696.DriveDataSource>(
      () => _i696.DriveDataSourceImpl(
        gh<_i361.Dio>(instanceName: 'files_dio'),
        gh<_i193.GoogleAuthDataSource>(),
      ),
    );
    gh.lazySingleton<_i345.ApiClient>(
      () => _i345.ApiClient(gh<_i361.Dio>(instanceName: 'files_dio')),
    );
    gh.lazySingleton<_i917.PageDownloadQueue>(
      () =>
          _i917.BackgroundPageDownloadQueue(gh<_i736.DownloadFileDataSource>()),
    );
    gh.lazySingleton<_i697.DownloadLocalDataSource>(
      () => _i697.DownloadLocalDataSourceImpl(
        gh<_i738.Box<String>>(instanceName: 'downloads'),
        gh<_i738.Box<String>>(instanceName: 'download_comics'),
      ),
    );
    gh.lazySingleton<_i480.SettingsLocalDataSource>(
      () => _i480.SettingsLocalDataSourceImpl(
        gh<_i738.Box<String>>(instanceName: 'settings'),
      ),
    );
    gh.lazySingleton<_i308.BookmarkLocalDataSource>(
      () => _i308.BookmarkLocalDataSourceImpl(
        gh<_i738.Box<String>>(instanceName: 'bookmarks'),
      ),
    );
    gh.lazySingleton<_i669.ExtensionManager>(
      () => _i669.ExtensionManager(
        gh<_i738.Box<String>>(instanceName: 'extensions'),
        gh<_i738.Box<String>>(instanceName: 'source_settings'),
        gh<_i361.Dio>(instanceName: 'files_dio'),
        gh<_i547.ExtensionBridge>(),
      ),
    );
    gh.lazySingleton<_i89.MigrationFileRepository>(
      () => _i387.MigrationFileRepositoryImpl(
        gh<_i168.MigrationFileDataSource>(),
      ),
    );
    gh.factory<_i905.PickMihonBackup>(
      () => _i905.PickMihonBackup(gh<_i89.MigrationFileRepository>()),
    );
    gh.factory<_i905.PickComixCsv>(
      () => _i905.PickComixCsv(gh<_i89.MigrationFileRepository>()),
    );
    gh.lazySingleton<_i669.SourceRegistry>(
      () => registerModule.sources(gh<_i669.ExtensionManager>()),
    );
    gh.lazySingleton<_i1050.LibraryJournal>(
      () => _i1050.LibraryJournal(
        gh<_i738.Box<String>>(instanceName: 'library_deletions'),
        gh<_i220.Clock>(),
      ),
    );
    gh.lazySingleton<_i509.TranslationRepository>(
      () => _i1064.TranslationRepositoryImpl(
        gh<_i761.NetworkInfo>(),
        gh<_i568.LlmTranslator>(),
        gh<_i701.TranslationCache>(),
      ),
    );
    gh.lazySingleton<_i328.HistoryRepository>(
      () => _i942.HistoryRepositoryImpl(
        gh<_i326.HistoryLocalDataSource>(),
        gh<_i1050.LibraryJournal>(),
      ),
    );
    gh.factory<_i814.AlignMergedHistory>(
      () => _i814.AlignMergedHistory(gh<_i328.HistoryRepository>()),
    );
    gh.lazySingleton<_i600.SyncRepository>(
      () => _i735.SyncRepositoryImpl(
        gh<_i193.GoogleAuthDataSource>(),
        gh<_i696.DriveDataSource>(),
        gh<_i308.BookmarkLocalDataSource>(),
        gh<_i326.HistoryLocalDataSource>(),
        gh<_i349.CategoryLocalDataSource>(),
        gh<_i1050.LibraryJournal>(),
        gh<_i738.Box<String>>(instanceName: 'sync'),
      ),
    );
    gh.lazySingleton<_i61.UpdateRemoteDataSource>(
      () => _i61.UpdateRemoteDataSourceImpl(gh<_i345.ApiClient>()),
    );
    gh.lazySingleton<_i614.BookmarkRepository>(
      () => _i299.BookmarkRepositoryImpl(
        gh<_i308.BookmarkLocalDataSource>(),
        gh<_i1050.LibraryJournal>(),
      ),
    );
    gh.lazySingleton<_i136.CategoryRepository>(
      () => _i819.CategoryRepositoryImpl(
        gh<_i349.CategoryLocalDataSource>(),
        gh<_i1050.LibraryJournal>(),
      ),
    );
    gh.factory<_i296.TranslatePage>(
      () => _i296.TranslatePage(gh<_i509.TranslationRepository>()),
    );
    gh.factory<_i934.GetBookmarks>(
      () => _i934.GetBookmarks(gh<_i614.BookmarkRepository>()),
    );
    gh.factory<_i934.SaveBookmarks>(
      () => _i934.SaveBookmarks(gh<_i614.BookmarkRepository>()),
    );
    gh.factory<_i934.RemoveBookmarks>(
      () => _i934.RemoveBookmarks(gh<_i614.BookmarkRepository>()),
    );
    gh.factory<_i1020.RestoreSyncAccount>(
      () => _i1020.RestoreSyncAccount(gh<_i600.SyncRepository>()),
    );
    gh.factory<_i1020.SignInSync>(
      () => _i1020.SignInSync(gh<_i600.SyncRepository>()),
    );
    gh.factory<_i1020.SignOutSync>(
      () => _i1020.SignOutSync(gh<_i600.SyncRepository>()),
    );
    gh.lazySingleton<_i87.SettingsRepository>(
      () => _i918.SettingsRepositoryImpl(gh<_i480.SettingsLocalDataSource>()),
    );
    gh.factory<_i216.GetCategories>(
      () => _i216.GetCategories(gh<_i136.CategoryRepository>()),
    );
    gh.factory<_i216.SaveCategories>(
      () => _i216.SaveCategories(gh<_i136.CategoryRepository>()),
    );
    gh.factory<_i216.DeleteCategories>(
      () => _i216.DeleteCategories(gh<_i136.CategoryRepository>()),
    );
    gh.factory<_i216.GetComicCategories>(
      () => _i216.GetComicCategories(gh<_i136.CategoryRepository>()),
    );
    gh.factory<_i216.SaveComicCategories>(
      () => _i216.SaveComicCategories(gh<_i136.CategoryRepository>()),
    );
    gh.factory<_i602.MigrateLocalLibrary>(
      () => _i602.MigrateLocalLibrary(
        gh<_i600.SyncRepository>(),
        gh<_i602.MigrateSnapshot>(),
        gh<_i220.Clock>(),
      ),
    );
    gh.factory<_i1020.SyncLibrary>(
      () => _i1020.SyncLibrary(
        gh<_i600.SyncRepository>(),
        gh<_i602.MigrateSnapshot>(),
        gh<_i220.Clock>(),
      ),
    );
    gh.factory<_i576.ExtensionsCubit>(
      () => _i576.ExtensionsCubit(gh<_i669.ExtensionManager>()),
    );
    gh.factory<_i165.SourcesCubit>(
      () => _i165.SourcesCubit(gh<_i669.ExtensionManager>()),
    );
    gh.factory<_i553.GetHistory>(
      () => _i553.GetHistory(gh<_i328.HistoryRepository>()),
    );
    gh.factory<_i553.SaveHistory>(
      () => _i553.SaveHistory(gh<_i328.HistoryRepository>()),
    );
    gh.factory<_i553.RemoveHistory>(
      () => _i553.RemoveHistory(gh<_i328.HistoryRepository>()),
    );
    gh.factory<_i553.RemoveComicHistory>(
      () => _i553.RemoveComicHistory(gh<_i328.HistoryRepository>()),
    );
    gh.factory<_i553.ClearHistory>(
      () => _i553.ClearHistory(gh<_i328.HistoryRepository>()),
    );
    gh.factory<_i3.SyncCubit>(
      () => _i3.SyncCubit(
        gh<_i1020.RestoreSyncAccount>(),
        gh<_i1020.SignInSync>(),
        gh<_i1020.SignOutSync>(),
        gh<_i1020.SyncLibrary>(),
        gh<_i602.MigrateLocalLibrary>(),
        gh<_i1050.LibraryJournal>(),
      ),
    );
    gh.lazySingleton<_i474.SeriesRemoteDataSource>(
      () => _i474.SeriesRemoteDataSourceImpl(gh<_i669.SourceRegistry>()),
    );
    gh.factory<_i364.ApplyPendingReads>(
      () => _i364.ApplyPendingReads(
        gh<_i70.PendingReadRepository>(),
        gh<_i328.HistoryRepository>(),
        gh<_i220.Clock>(),
      ),
    );
    gh.lazySingleton<_i757.UpdateRepository>(
      () => _i747.UpdateRepositoryImpl(
        gh<_i61.UpdateRemoteDataSource>(),
        gh<_i850.AppInstaller>(),
        gh<_i761.NetworkInfo>(),
      ),
    );
    gh.factory<_i618.BackupLibrary>(
      () => _i618.BackupLibrary(
        gh<_i261.BackupRepository>(),
        gh<_i614.BookmarkRepository>(),
        gh<_i328.HistoryRepository>(),
        gh<_i136.CategoryRepository>(),
      ),
    );
    gh.factory<_i618.RestoreLibrary>(
      () => _i618.RestoreLibrary(
        gh<_i261.BackupRepository>(),
        gh<_i614.BookmarkRepository>(),
        gh<_i328.HistoryRepository>(),
        gh<_i136.CategoryRepository>(),
      ),
    );
    gh.factory<_i1023.MigrateComic>(
      () => _i1023.MigrateComic(
        gh<_i614.BookmarkRepository>(),
        gh<_i328.HistoryRepository>(),
        gh<_i136.CategoryRepository>(),
        gh<_i220.Clock>(),
        gh<_i70.PendingReadRepository>(),
      ),
    );
    gh.lazySingleton<_i609.ComicDetailRepository>(
      () => _i231.ComicDetailRepositoryImpl(
        gh<_i474.SeriesRemoteDataSource>(),
        gh<_i761.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i401.ReaderRepository>(
      () => _i380.ReaderRepositoryImpl(
        gh<_i474.SeriesRemoteDataSource>(),
        gh<_i761.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i331.ExploreRepository>(
      () => _i521.ExploreRepositoryImpl(
        gh<_i474.SeriesRemoteDataSource>(),
        gh<_i761.NetworkInfo>(),
      ),
    );
    gh.factory<_i206.SearchSource>(
      () => _i206.SearchSource(gh<_i331.ExploreRepository>()),
    );
    gh.factory<_i814.SetMergedSources>(
      () => _i814.SetMergedSources(gh<_i614.BookmarkRepository>()),
    );
    gh.factory<_i730.GetSettings>(
      () => _i730.GetSettings(gh<_i87.SettingsRepository>()),
    );
    gh.factory<_i730.SaveSettings>(
      () => _i730.SaveSettings(gh<_i87.SettingsRepository>()),
    );
    gh.factory<_i1054.ImportLibrary>(
      () => _i1054.ImportLibrary(
        gh<_i614.BookmarkRepository>(),
        gh<_i136.CategoryRepository>(),
        gh<_i70.PendingReadRepository>(),
        gh<_i328.HistoryRepository>(),
        gh<_i220.Clock>(),
      ),
    );
    gh.factory<_i364.CompleteImportedComic>(
      () => _i364.CompleteImportedComic(
        gh<_i614.BookmarkRepository>(),
        gh<_i364.ApplyPendingReads>(),
        gh<_i220.Clock>(),
      ),
    );
    gh.factory<_i151.BackupCubit>(
      () => _i151.BackupCubit(
        gh<_i618.BackupLibrary>(),
        gh<_i618.RestoreLibrary>(),
      ),
    );
    gh.factory<_i277.CategoryCubit>(
      () => _i277.CategoryCubit(
        gh<_i216.GetCategories>(),
        gh<_i216.SaveCategories>(),
        gh<_i216.DeleteCategories>(),
        gh<_i216.GetComicCategories>(),
        gh<_i216.SaveComicCategories>(),
        gh<_i220.Clock>(),
      ),
    );
    gh.factory<_i928.CheckForUpdate>(
      () => _i928.CheckForUpdate(gh<_i757.UpdateRepository>()),
    );
    gh.factory<_i928.InstallUpdate>(
      () => _i928.InstallUpdate(gh<_i757.UpdateRepository>()),
    );
    gh.factory<_i814.FetchMergedChapters>(
      () => _i814.FetchMergedChapters(gh<_i609.ComicDetailRepository>()),
    );
    gh.factory<_i708.RefreshBookmark>(
      () => _i708.RefreshBookmark(
        gh<_i614.BookmarkRepository>(),
        gh<_i609.ComicDetailRepository>(),
        gh<_i364.ApplyPendingReads>(),
        gh<_i220.Clock>(),
        gh<_i814.FetchMergedChapters>(),
        gh<_i814.AlignMergedHistory>(),
      ),
    );
    gh.lazySingleton<_i478.LatestRepository>(
      () => _i175.LatestRepositoryImpl(
        gh<_i474.SeriesRemoteDataSource>(),
        gh<_i761.NetworkInfo>(),
        gh<_i669.SourceRegistry>(),
      ),
    );
    gh.factory<_i309.HistoryCubit>(
      () => _i309.HistoryCubit(
        gh<_i553.GetHistory>(),
        gh<_i553.SaveHistory>(),
        gh<_i553.RemoveHistory>(),
        gh<_i553.RemoveComicHistory>(),
        gh<_i553.ClearHistory>(),
        gh<_i220.Clock>(),
      ),
    );
    gh.factory<_i206.MigrateToSource>(
      () => _i206.MigrateToSource(
        gh<_i609.ComicDetailRepository>(),
        gh<_i1023.MigrateComic>(),
      ),
    );
    gh.lazySingleton<_i766.HomeRepository>(
      () => _i782.HomeRepositoryImpl(
        gh<_i474.SeriesRemoteDataSource>(),
        gh<_i761.NetworkInfo>(),
        gh<_i669.SourceRegistry>(),
      ),
    );
    gh.lazySingleton<_i1026.DownloadRepository>(
      () => _i461.DownloadRepositoryImpl(
        gh<_i697.DownloadLocalDataSource>(),
        gh<_i736.DownloadFileDataSource>(),
        gh<_i917.PageDownloadQueue>(),
        gh<_i401.ReaderRepository>(),
        gh<_i220.Clock>(),
      ),
    );
    gh.factory<_i783.ExploreComics>(
      () => _i783.ExploreComics(gh<_i331.ExploreRepository>()),
    );
    gh.factory<_i814.MergeComic>(
      () => _i814.MergeComic(
        gh<_i614.BookmarkRepository>(),
        gh<_i328.HistoryRepository>(),
        gh<_i136.CategoryRepository>(),
        gh<_i609.ComicDetailRepository>(),
        gh<_i70.PendingReadRepository>(),
        gh<_i814.AlignMergedHistory>(),
        gh<_i220.Clock>(),
      ),
    );
    gh.factory<_i116.GetLatestComics>(
      () => _i116.GetLatestComics(gh<_i478.LatestRepository>()),
    );
    gh.factory<_i625.SettingsCubit>(
      () => _i625.SettingsCubit(
        gh<_i730.GetSettings>(),
        gh<_i730.SaveSettings>(),
      ),
    );
    gh.factory<_i140.MihonImportCubit>(
      () => _i140.MihonImportCubit(
        gh<_i905.PickMihonBackup>(),
        gh<_i1054.ImportLibrary>(),
        gh<_i669.ExtensionManager>(),
      ),
    );
    gh.factory<_i784.GetComicDetails>(
      () => _i784.GetComicDetails(
        gh<_i609.ComicDetailRepository>(),
        gh<_i1026.DownloadRepository>(),
        gh<_i614.BookmarkRepository>(),
        gh<_i328.HistoryRepository>(),
        gh<_i814.FetchMergedChapters>(),
      ),
    );
    gh.factory<_i183.GetDownloads>(
      () => _i183.GetDownloads(gh<_i1026.DownloadRepository>()),
    );
    gh.factory<_i183.WatchDownloads>(
      () => _i183.WatchDownloads(gh<_i1026.DownloadRepository>()),
    );
    gh.factory<_i183.EnqueueDownloads>(
      () => _i183.EnqueueDownloads(gh<_i1026.DownloadRepository>()),
    );
    gh.factory<_i183.RetryDownloads>(
      () => _i183.RetryDownloads(gh<_i1026.DownloadRepository>()),
    );
    gh.factory<_i183.DeleteDownloads>(
      () => _i183.DeleteDownloads(gh<_i1026.DownloadRepository>()),
    );
    gh.factory<_i183.SyncDownloads>(
      () => _i183.SyncDownloads(gh<_i1026.DownloadRepository>()),
    );
    gh.factory<_i183.ClearDownloads>(
      () => _i183.ClearDownloads(gh<_i1026.DownloadRepository>()),
    );
    gh.factory<_i715.UpdateCubit>(
      () => _i715.UpdateCubit(
        gh<_i928.CheckForUpdate>(),
        gh<_i928.InstallUpdate>(),
      ),
    );
    gh.factory<_i307.LatestBloc>(
      () => _i307.LatestBloc(gh<_i116.GetLatestComics>()),
    );
    gh.factory<_i47.ExploreBloc>(
      () => _i47.ExploreBloc(gh<_i783.ExploreComics>()),
    );
    gh.factory<_i896.MatchCubit>(
      () => _i896.MatchCubit(
        gh<_i206.SearchSource>(),
        gh<_i206.MigrateToSource>(),
        gh<_i1054.ImportLibrary>(),
        gh<_i220.Clock>(),
      ),
    );
    gh.factory<_i107.GetHome>(() => _i107.GetHome(gh<_i766.HomeRepository>()));
    gh.factory<_i865.GetChapterContent>(
      () => _i865.GetChapterContent(
        gh<_i401.ReaderRepository>(),
        gh<_i1026.DownloadRepository>(),
      ),
    );
    gh.factory<_i48.ComicDetailsBloc>(
      () => _i48.ComicDetailsBloc(gh<_i784.GetComicDetails>()),
    );
    gh.factory<_i527.BookmarkCubit>(
      () => _i527.BookmarkCubit(
        gh<_i934.GetBookmarks>(),
        gh<_i934.SaveBookmarks>(),
        gh<_i934.RemoveBookmarks>(),
        gh<_i708.RefreshBookmark>(),
        gh<_i1023.MigrateComic>(),
        gh<_i364.CompleteImportedComic>(),
        gh<_i675.ProgressNotifier>(),
        gh<_i220.Clock>(),
        gh<_i814.MergeComic>(),
        gh<_i814.SetMergedSources>(),
        gh<_i814.AlignMergedHistory>(),
      ),
    );
    gh.factory<_i641.DownloadCubit>(
      () => _i641.DownloadCubit(
        gh<_i183.GetDownloads>(),
        gh<_i183.WatchDownloads>(),
        gh<_i183.EnqueueDownloads>(),
        gh<_i183.RetryDownloads>(),
        gh<_i183.DeleteDownloads>(),
        gh<_i183.ClearDownloads>(),
        gh<_i183.SyncDownloads>(),
      ),
    );
    gh.factory<_i399.ReaderBloc>(
      () => _i399.ReaderBloc(gh<_i865.GetChapterContent>()),
    );
    gh.factory<_i657.HomeBloc>(() => _i657.HomeBloc(gh<_i107.GetHome>()));
    return this;
  }
}

class _$RegisterModule extends _i1041.RegisterModule {}

class _$StorageModule extends _i671.StorageModule {}

class _$AppInstallerModule extends _i850.AppInstallerModule {}

class _$GoogleAuthModule extends _i193.GoogleAuthModule {}
