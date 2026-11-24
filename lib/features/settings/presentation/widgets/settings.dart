import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/constants/variables.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:yoru/core/utils/utils.dart';
import 'package:yoru/features/settings/domain/entities/app_settings.dart';
import 'package:yoru/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:yoru/features/settings/presentation/pages/settings_pages.dart';
import 'package:yoru/features/settings/presentation/widgets/app_info.dart';
import 'package:yoru/features/source/presentation/bloc/sources_cubit.dart';
import 'package:yoru/features/sync/presentation/widgets/sync_section.dart';
import 'package:yoru/features/translate/presentation/pages/translate_settings_screen.dart';
import 'package:yoru/features/update/presentation/bloc/update_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:url_launcher/url_launcher.dart';

/// More: incognito mode, then one row per settings group (Sources,
/// Library, Translation, Backup, Appearance), each opening its own screen,
/// SYNC (Google Drive) and ABOUT (updates, the app, bug reports).
class Settings extends StatelessWidget {
  const Settings({super.key, this.appVersion = ''});

  /// Shown next to "Check for updates".
  final String appVersion;

  Future<void> _reportBug(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(AppVariables.reportLink),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      showSnackBar(context: context, message: AppText.t.linkFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkingUpdate = context.select<UpdateCubit, bool>(
      (u) => u.state is UpdateChecking,
    );
    final updateAvailable = context.select<UpdateCubit, bool>(
      (u) => u.state is UpdateAvailable,
    );
    final incognito = context.select<SettingsCubit, bool>(
      (s) => s.state.incognito,
    );
    void setIncognito(bool on) =>
        context.read<SettingsCubit>().update((s) => s.copyWith(incognito: on));
    final extensionUpdates = context.select<SourcesCubit, int>(
      (s) => s.state.updateCount,
    );
    final translateLabel = context.select<SettingsCubit, String>(
      (s) => translateSettingLabel(s.state),
    );
    final themeMode = context.select<SettingsCubit, AppThemeMode>(
      (s) => s.state.themeMode,
    );
    final language = context.select<SettingsCubit, AppLanguage>(
      (s) => s.state.language,
    );

    void open(String title, Widget child) =>
        SettingsSubScreen.open(context, title: title, child: child);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: DotSpace.s5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: ListGroup(
            children: [
              ListRow(
                icon: LucideIcons300.hatGlasses,
                title: AppText.t.incognito,
                subtitle: AppText.t.incognitoDescription,
                trailing: DotSwitch(
                  value: incognito,
                  semanticLabel: AppText.t.incognito,
                  onChanged: setIncognito,
                ),
                onTap: () => setIncognito(!incognito),
              ),
            ],
          ),
        ),
        const SizedBox(height: DotSpace.s3),
        SectionLabel(label: AppText.t.settings),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: ListGroup(
            children: [
              ListRow(
                icon: LucideIcons300.puzzle,
                title: AppText.t.sources,
                subtitle: AppText.t.sourcesMenuDescription,
                trailing: extensionUpdates == 0
                    ? null
                    : UpdateBadge(count: extensionUpdates),
                showChevron: true,
                onTap: () => open(AppText.t.sources, const SourcesSettings()),
              ),
              ListRow(
                icon: LucideIcons300.libraryBig,
                title: AppText.t.library,
                subtitle: AppText.t.libraryMenuDescription,
                showChevron: true,
                onTap: () => open(AppText.t.library, const LibrarySettings()),
              ),
              ListRow(
                icon: LucideIcons300.languages,
                title: AppText.t.translation,
                subtitle: AppText.t.translatePagesDescription,
                value: translateLabel,
                showChevron: true,
                onTap: () => TranslateSettingsScreen.open(context),
              ),
              ListRow(
                icon: LucideIcons300.database,
                title: AppText.t.backup,
                subtitle: AppText.t.backupMenuDescription,
                showChevron: true,
                onTap: () => open(AppText.t.backup, const BackupSettings()),
              ),
              ListRow(
                icon: LucideIcons300.palette,
                title: AppText.t.appearance,
                subtitle: AppText.t.appearanceMenuDescription,
                value:
                    '${switch (themeMode) {
                      AppThemeMode.system => AppText.t.themeSystem,
                      AppThemeMode.light => AppText.t.themeLight,
                      AppThemeMode.dark => AppText.t.themeDark,
                    }} · ${language.nativeName}',
                showChevron: true,
                onTap: () =>
                    open(AppText.t.appearance, const AppearanceSettings()),
              ),
            ],
          ),
        ),
        // One group, so right here rather than a screen of its own.
        const SyncSection(),
        const SizedBox(height: DotSpace.s3),
        SectionLabel(label: AppText.t.about),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: ListGroup(
            children: [
              if (!AppVariables.storeBuild)
                ListRow(
                  icon: LucideIcons300.refreshCw,
                  title: AppText.t.checkUpdate,
                  value: updateAvailable
                      ? AppText.t.updateAvailable
                      : appVersion.isEmpty
                      ? null
                      : 'v$appVersion',
                  showChevron: true,
                  onTap: checkingUpdate
                      ? null
                      : () => context.read<UpdateCubit>().check(),
                ),
              ListRow(
                icon: LucideIcons300.info,
                title: AppText.t.aboutApp,
                subtitle: AppText.t.aboutAppDescription,
                showChevron: true,
                onTap: () => showDotSheet<void>(
                  context: context,
                  builder: (_) => const AppInfo(),
                ),
              ),
              ListRow(
                icon: LucideIcons300.bug,
                title: AppText.t.bugReport,
                subtitle: AppText.t.bugReportDescription,
                showChevron: true,
                onTap: () => _reportBug(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
