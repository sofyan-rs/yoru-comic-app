import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:yoru/features/settings/domain/entities/app_settings.dart';
import 'package:yoru/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// "Reader settings": direction, page size, keep awake, page gap and
/// progress bar; in the vertical reader also infinite scroll and the
/// auto-scroll speed, and on wide screens page width and (sideways) two
/// pages. Only what applies to the reader as set is shown. Saved right away
/// through [SettingsCubit].
class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final settings = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();
    final size = MediaQuery.sizeOf(context);
    final vertical = settings.readingDirection == ReadingDirection.vertical;
    // Only wide screens have room for a choice of widths or two pages.
    final wide = size.width >= DotSize.splitMinWidth;
    // As the reader decides: two pages show on a landscape window, each
    // pair fitted to the screen whole, so page size and width don't apply.
    final spreads =
        wide && !vertical && settings.twoPages && size.width > size.height;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: DotSpace.s5, bottom: DotSpace.s3),
      child: Text(
        text.toUpperCase(),
        style: DotlineText.label.copyWith(color: c.inkFaint),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppText.t.readerSettings,
          style: DotlineText.title.copyWith(color: c.ink),
        ),
        label(AppText.t.readingDirection),
        SegmentedControl<ReadingDirection>(
          background: c.bg,
          selected: settings.readingDirection,
          onChanged: (d) =>
              cubit.update((s) => s.copyWith(readingDirection: d)),
          segments: [
            Segment(
              value: ReadingDirection.vertical,
              label: AppText.t.directionVertical,
            ),
            Segment(
              value: ReadingDirection.rightToLeft,
              label: AppText.t.directionRtl,
            ),
            Segment(
              value: ReadingDirection.leftToRight,
              label: AppText.t.directionLtr,
            ),
          ],
        ),
        if (!spreads) ...[
          label(AppText.t.pageSize),
          SegmentedControl<PageFit>(
            background: c.bg,
            selected: settings.pageFit,
            onChanged: (f) => cubit.update((s) => s.copyWith(pageFit: f)),
            segments: [
              Segment(value: PageFit.width, label: AppText.t.fitWidth),
              Segment(value: PageFit.height, label: AppText.t.fitHeight),
            ],
          ),
        ],
        if (wide && !spreads && settings.pageFit == PageFit.width) ...[
          label(AppText.t.pageWidth),
          SegmentedControl<ReaderWidth>(
            background: c.bg,
            selected: settings.readerWidth,
            onChanged: (w) => cubit.update((s) => s.copyWith(readerWidth: w)),
            segments: [
              Segment(value: ReaderWidth.narrow, label: AppText.t.widthNarrow),
              Segment(value: ReaderWidth.medium, label: AppText.t.widthMedium),
              Segment(value: ReaderWidth.wide, label: AppText.t.widthWide),
              Segment(value: ReaderWidth.full, label: AppText.t.widthFull),
            ],
          ),
        ],
        const SizedBox(height: DotSpace.s5),
        ListGroup(
          background: c.bg,
          children: [
            ListRow(
              title: AppText.t.keepScreenOn,
              subtitle: AppText.t.keepScreenOnHint,
              trailing: DotSwitch(
                value: settings.keepScreenOn,
                semanticLabel: AppText.t.keepScreenOn,
                onChanged: (v) =>
                    cubit.update((s) => s.copyWith(keepScreenOn: v)),
              ),
              onTap: () => cubit.update(
                (s) => s.copyWith(keepScreenOn: !s.keepScreenOn),
              ),
            ),
            if (wide && !vertical)
              ListRow(
                title: AppText.t.twoPages,
                subtitle: AppText.t.twoPagesHint,
                trailing: DotSwitch(
                  value: settings.twoPages,
                  semanticLabel: AppText.t.twoPages,
                  onChanged: (v) =>
                      cubit.update((s) => s.copyWith(twoPages: v)),
                ),
                onTap: () =>
                    cubit.update((s) => s.copyWith(twoPages: !s.twoPages)),
              ),
            ListRow(
              title: AppText.t.pageGap,
              subtitle: AppText.t.pageGapHint,
              trailing: DotSwitch(
                value: settings.pageGap,
                semanticLabel: AppText.t.pageGap,
                onChanged: (v) => cubit.update((s) => s.copyWith(pageGap: v)),
              ),
              onTap: () => cubit.update((s) => s.copyWith(pageGap: !s.pageGap)),
            ),
            ListRow(
              title: AppText.t.progressBar,
              subtitle: AppText.t.progressBarHint,
              trailing: DotSwitch(
                value: settings.progressBar,
                semanticLabel: AppText.t.progressBar,
                onChanged: (v) =>
                    cubit.update((s) => s.copyWith(progressBar: v)),
              ),
              onTap: () =>
                  cubit.update((s) => s.copyWith(progressBar: !s.progressBar)),
            ),
            if (vertical) ...[
              ListRow(
                title: AppText.t.infiniteScroll,
                subtitle: AppText.t.infiniteScrollHint,
                trailing: DotSwitch(
                  value: settings.infiniteScroll,
                  semanticLabel: AppText.t.infiniteScroll,
                  onChanged: (v) =>
                      cubit.update((s) => s.copyWith(infiniteScroll: v)),
                ),
                onTap: () => cubit.update(
                  (s) => s.copyWith(infiniteScroll: !s.infiniteScroll),
                ),
              ),
              ListRow(
                title: AppText.t.autoScrollSpeed,
                subtitle: AppText.t.autoScrollHint,
                trailing: _SpeedStepper(
                  value: settings.autoScrollSpeed,
                  onChanged: (v) =>
                      cubit.update((s) => s.copyWith(autoScrollSpeed: v)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// `-  3  +` for the auto-scroll speed level.
class _SpeedStepper extends StatelessWidget {
  const _SpeedStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RoundIconButton(
          icon: LucideIcons300.minus,
          semanticLabel: AppText.t.slower,
          size: 36,
          iconSize: DotSize.iconSmall,
          onTap: value > autoScrollMin ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: DotlineText.data.copyWith(color: c.ink),
          ),
        ),
        RoundIconButton(
          icon: LucideIcons300.plus,
          semanticLabel: AppText.t.faster,
          size: 36,
          iconSize: DotSize.iconSmall,
          onTap: value < autoScrollMax ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
