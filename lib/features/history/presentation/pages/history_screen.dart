import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:yoru/features/history/presentation/bloc/history_cubit.dart';
import 'package:yoru/features/history/presentation/widgets/history_comic_card.dart';
import 'package:yoru/features/history/presentation/widgets/history_groups.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// History tab: last read chapter per comic, grouped by day.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _confirmClearAll(BuildContext context) async {
    final cubit = context.read<HistoryCubit>();
    final confirmed = await showDotSheet<bool>(
      context: context,
      builder: (context) {
        final c = Dotline.of(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActionSheetHeader(
              icon: LucideIcons300.trash2,
              title: AppText.t.clearHistory,
            ),
            const SizedBox(height: DotSpace.s4),
            Text(
              AppText.t.clearHistoryConfirmation,
              style: DotlineText.body.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: DotSpace.s5),
            DotButton.destructive(
              label: AppText.t.clearHistory,
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: DotSpace.s3),
            DotButton.outline(
              label: AppText.t.cancel,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        );
      },
    );
    if (confirmed == true) await cubit.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final latest = context.watch<HistoryCubit>().latestHistories;
    final days = HistoryDay.group(latest, DateTime.now());
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Outside the scroll view so the title stays put.
            CenteredContent(
              child: ScreenHeader(
                title: AppText.t.historyTab,
                subtitle: latest.isEmpty
                    ? null
                    : '${AppText.t.comicCount(latest.length)} · '
                          '${AppText.t.swipeToDelete}',
                actions: [
                  if (latest.isNotEmpty)
                    RoundIconButton(
                      icon: LucideIcons300.trash2,
                      semanticLabel: AppText.t.clearHistory,
                      iconSize: DotSize.iconSmall,
                      onTap: () => _confirmClearAll(context),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SlidableAutoCloseBehavior(
                child: CustomScrollView(
                  slivers: [
                    SliverCenteredContent(
                      slivers: [
                        if (latest.isEmpty)
                          SliverToBoxAdapter(
                            child: EmptyState(
                              icon: LucideIcons300.history,
                              title: AppText.t.historyEmpty,
                              message: AppText.t.historyEmptyHint,
                            ),
                          ),
                        for (final day in days) ...[
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              DotSpace.s4,
                              0,
                              DotSpace.s4,
                              DotSpace.s3,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                day.label.toUpperCase(),
                                style: DotlineText.label.copyWith(
                                  color: c.inkFaint,
                                ),
                              ),
                            ),
                          ),
                          SliverListGroup(
                            itemCount: day.items.length,
                            itemBuilder: (context, index) =>
                                HistoryComicCard(item: day.items[index]),
                          ),
                          const SliverPadding(
                            padding: EdgeInsets.only(bottom: DotSpace.s5),
                          ),
                        ],
                      ],
                    ),
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: bottomInset),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
