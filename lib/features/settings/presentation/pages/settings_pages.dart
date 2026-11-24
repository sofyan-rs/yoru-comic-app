import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/network/image_cache.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:yoru/core/utils/utils.dart';
import 'package:yoru/features/backup/presentation/bloc/backup_cubit.dart';
import 'package:yoru/features/category/presentation/pages/categories_screen.dart';
import 'package:yoru/features/download/presentation/bloc/download_cubit.dart';
import 'package:yoru/features/download/presentation/pages/downloads_screen.dart';
import 'package:yoru/features/local/presentation/local_import.dart';
import 'package:yoru/features/migration/presentation/pages/import_screen.dart';
import 'package:yoru/features/migration/presentation/pages/source_migration_screen.dart';
import 'package:yoru/features/settings/domain/entities/app_settings.dart';
import 'package:yoru/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:yoru/features/settings/presentation/widgets/clear_cache_sheet.dart';
import 'package:yoru/features/settings/presentation/widgets/dns_sheet.dart';
import 'package:yoru/features/settings/presentation/widgets/language_sheet.dart';
import 'package:yoru/features/source/presentation/bloc/sources_cubit.dart';
import 'package:yoru/features/source/presentation/pages/extensions_screen.dart';

/// A settings group from More on its own screen: [title] in the top bar
/// and [child] (its rows) below.
class SettingsSubScreen extends StatelessWidget {
  const SettingsSubScreen({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  static Future<void> open(
    BuildContext context, {
    required String title,
    required Widget child,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => SettingsSubScreen(title: title, child: child),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          // Outside the scroll view so the title stays put.
          DotTopBar(title: title),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                padding: contentInset(constraints.maxWidth).copyWith(
                  top: DotSpace.s4,
                  bottom: DotSpace.s6 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [child],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Rows in a card, with the screen's side margin.
class _Group extends StatelessWidget {
  const _Group(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
    child: ListGroup(children: children),
  );
}

/// Sources: extensions, moving the library to another source, DNS over
/// HTTPS.
class SourcesSettings extends StatelessWidget {
  const SourcesSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final extensionUpdates = context.select<SourcesCubit, int>(
      (s) => s.state.updateCount,
    );
    final dnsSetting = context.select<SettingsCubit, String>(
      (s) => s.state.dnsOverHttps,
    );
    return _Group([
      ListRow(
        icon: LucideIcons300.puzzle,
        title: AppText.t.extensions,
        subtitle: AppText.t.extensionsDescription,
        trailing: extensionUpdates == 0
            ? null
            : UpdateBadge(count: extensionUpdates),
        showChevron: true,
        onTap: () => ExtensionsScreen.open(context),
      ),
      ListRow(
        icon: LucideIcons300.arrowRightLeft,
        title: AppText.t.migrateSource,
        subtitle: AppText.t.migrateSourceDescription,
        showChevron: true,
        onTap: () => SourceMigrationScreen.open(context),
      ),
      ListRow(
        icon: LucideIcons300.globeLock,
        title: AppText.t.dnsOverHttps,
        subtitle: AppText.t.dnsOverHttpsDescription,
        value: dnsSettingLabel(dnsSetting),
        showChevron: true,
        onTap: () => showDnsSheet(context),
      ),
    ]);
  }
}

/// Library: importing comics, categories, downloads, the image cache.
class LibrarySettings extends StatefulWidget {
  const LibrarySettings({super.key});

  @override
  State<LibrarySettings> createState() => _LibrarySettingsState();
}

class _LibrarySettingsState extends State<LibrarySettings> {
  int _cacheBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final bytes = await comicImageCache.store.getCacheSize();
    if (mounted) setState(() => _cacheBytes = bytes);
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirmed = await showDotSheet<bool>(
      context: context,
      builder: (_) => const ClearCacheSheet(),
    );
    if (confirmed != true) return;
    await comicImageCache.emptyCache();
    await _loadCacheSize();
    if (context.mounted) {
      showSnackBar(context: context, message: AppText.t.cacheCleared);
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadedBytes = context.select<DownloadCubit, int>(
      (d) => d.state.totalBytes,
    );
    return _Group([
      ListRow(
        icon: LucideIcons300.folderInput,
        title: AppText.t.importComics,
        subtitle: canImportFolders
            ? AppText.t.importComicsDescription
            : AppText.t.importComicsDescriptionFiles,
        showChevron: true,
        onTap: () => importLocalComics(context),
      ),
      ListRow(
        icon: LucideIcons300.folder,
        title: AppText.t.categories,
        subtitle: AppText.t.groupByCategoryDescription,
        showChevron: true,
        onTap: () => CategoriesScreen.open(context),
      ),
      ListRow(
        icon: LucideIcons300.download,
        title: AppText.t.downloads,
        subtitle: AppText.t.downloadsDescription,
        value: downloadedBytes == 0 ? null : formatBytes(downloadedBytes),
        showChevron: true,
        onTap: () => DownloadsScreen.open(context),
      ),
      ListRow(
        icon: LucideIcons300.trash2,
        title: AppText.t.clearCache,
        subtitle: AppText.t.clearCacheDescription,
        value: _cacheBytes == 0 ? null : formatBytes(_cacheBytes),
        showChevron: false,
        onTap: () => _clearCache(context),
      ),
    ]);
  }
}

/// Backup: to a file, from a file, from other apps.
class BackupSettings extends StatelessWidget {
  const BackupSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<BackupCubit>().state is BackupBusy;
    return _Group([
      ListRow(
        icon: LucideIcons300.database,
        title: AppText.t.backupData,
        subtitle: AppText.t.backupDataDescription,
        onTap: busy ? null : () => context.read<BackupCubit>().backup(),
      ),
      ListRow(
        icon: LucideIcons300.rotateCcw,
        title: AppText.t.restoreData,
        subtitle: AppText.t.restoreDataDescription,
        onTap: busy ? null : () => context.read<BackupCubit>().restore(),
      ),
      ListRow(
        icon: LucideIcons300.archiveRestore,
        title: AppText.t.importFromApps,
        subtitle: AppText.t.importFromAppsDescription,
        showChevron: true,
        onTap: () => ImportScreen.open(context),
      ),
    ]);
  }
}

/// Appearance: theme, language, the cover animation and Home's sound.
class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsCubit>();
    void update(AppSettings Function(AppSettings) change) =>
        settings.update(change);
    final themeMode = context.select<SettingsCubit, AppThemeMode>(
      (s) => s.state.themeMode,
    );
    final language = context.select<SettingsCubit, AppLanguage>(
      (s) => s.state.language,
    );
    final coverAnimation = context.select<SettingsCubit, bool>(
      (s) => s.state.coverAnimation,
    );
    final kururinSound = context.select<SettingsCubit, bool>(
      (s) => s.state.kururinSound,
    );
    final lalalaUntilFinish = context.select<SettingsCubit, bool>(
      (s) => s.state.lalalaUntilFinish,
    );
    void setCoverAnimation(bool on) =>
        update((s) => s.copyWith(coverAnimation: on));
    void setKururinSound(bool on) =>
        update((s) => s.copyWith(kururinSound: on));
    void setLalalaUntilFinish(bool on) =>
        update((s) => s.copyWith(lalalaUntilFinish: on));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: SegmentedControl<AppThemeMode>(
            selected: themeMode,
            onChanged: settings.changeThemeMode,
            segments: [
              Segment(value: AppThemeMode.system, label: AppText.t.themeSystem),
              Segment(value: AppThemeMode.light, label: AppText.t.themeLight),
              Segment(value: AppThemeMode.dark, label: AppText.t.themeDark),
            ],
          ),
        ),
        const SizedBox(height: DotSpace.s3),
        _Group([
          ListRow(
            icon: LucideIcons300.languages,
            title: AppText.t.appLanguage,
            value: language.nativeName,
            showChevron: true,
            onTap: () => showLanguageSheet(context),
          ),
          ListRow(
            icon: LucideIcons300.sparkles,
            title: AppText.t.coverAnimation,
            subtitle: AppText.t.coverAnimationDescription,
            trailing: DotSwitch(
              value: coverAnimation,
              semanticLabel: AppText.t.coverAnimation,
              onChanged: setCoverAnimation,
            ),
            onTap: () => setCoverAnimation(!coverAnimation),
          ),
          ListRow(
            icon: LucideIcons300.volume2,
            title: AppText.t.kururinSound,
            subtitle: AppText.t.kururinSoundDescription,
            trailing: DotSwitch(
              value: kururinSound,
              semanticLabel: AppText.t.kururinSound,
              onChanged: setKururinSound,
            ),
            onTap: () => setKururinSound(!kururinSound),
          ),
          if (kururinSound)
            ListRow(
              icon: LucideIcons300.hourglass,
              title: AppText.t.lalalaUntilFinish,
              subtitle: AppText.t.lalalaUntilFinishDescription,
              trailing: DotSwitch(
                value: lalalaUntilFinish,
                semanticLabel: AppText.t.lalalaUntilFinish,
                onChanged: setLalalaUntilFinish,
              ),
              onTap: () => setLalalaUntilFinish(!lalalaUntilFinish),
            ),
        ]),
      ],
    );
  }
}
