import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:yoru/features/update/domain/entities/app_release.dart';
import 'package:yoru/features/update/presentation/bloc/update_cubit.dart';
import 'package:yoru/features/update/presentation/widgets/release_notes.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows [release]'s changes and downloads and installs it.
class UpdateSheet extends StatelessWidget {
  const UpdateSheet({super.key, required this.release});

  final AppRelease release;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final state = context.watch<UpdateCubit>().state;
    final changes = release.changes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(
          icon: LucideIcons300.download,
          title: AppText.t.updateAvailable,
          subtitle: '${AppText.t.version} ${release.version}',
        ),
        if (changes.isNotEmpty) ...[
          const SizedBox(height: DotSpace.s4),
          Flexible(child: SingleChildScrollView(child: ReleaseNotes(changes))),
        ],
        const SizedBox(height: DotSpace.s5),
        ...switch (state) {
          UpdateInstallingState() => [
            Text(AppText.t.updateInstalling, style: DotlineText.body),
            const SizedBox(height: DotSpace.s3),
            Text(
              AppText.t.updateApprovalHint,
              style: DotlineText.body.copyWith(color: c.inkFaint),
            ),
          ],
          UpdateDownloadingState(:final percent) => [
            Row(
              children: [
                Text(
                  '${AppText.t.updateDownloading} $percent%'.toUpperCase(),
                  style: DotlineText.label.copyWith(color: c.inkFaint),
                ),
                const Spacer(),
                DotMeter(value: percent, total: 100, dots: 20),
              ],
            ),
          ],
          UpdateInstallFailedState() => [
            Text(
              AppText.t.updateFailed,
              style: DotlineText.body.copyWith(color: c.accentText),
            ),
            const SizedBox(height: DotSpace.s3),
            DotButton(
              label: AppText.t.updateRetry,
              onTap: () => context.read<UpdateCubit>().install(),
            ),
          ],
          _ => [
            DotButton(
              label: AppText.t.updateNow,
              onTap: () => context.read<UpdateCubit>().install(),
            ),
          ],
        },
        const SizedBox(height: DotSpace.s3),
        DotButton.outline(
          label: AppText.t.viewRelease,
          onTap: () => launchUrl(
            Uri.parse(release.pageUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const SizedBox(height: DotSpace.s3),
        DotButton.outline(
          label: AppText.t.updateLater,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
