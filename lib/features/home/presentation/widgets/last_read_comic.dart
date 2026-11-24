import 'package:yoru/core/source/local/local_source.dart';
import 'package:yoru/core/source/comic_key.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/domain/entities/comic_details.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:yoru/features/bookmark/presentation/bloc/bookmark_cubit.dart';
import 'package:yoru/features/comic_detail/presentation/pages/comic_details_screen.dart';
import 'package:yoru/features/history/domain/entities/read_history.dart';
import 'package:yoru/features/history/domain/entities/read_progress.dart';
import 'package:yoru/features/history/domain/entities/resume_chapter.dart';
import 'package:yoru/features/history/presentation/bloc/history_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "LANJUT BACA" cards for the most recently read comics: one on narrow
/// screens, the two latest side by side on wide ones. Hidden when the
/// history is empty.
class LastReadComic extends StatelessWidget {
  const LastReadComic({super.key});

  @override
  Widget build(BuildContext context) {
    final recent = context.watch<HistoryCubit>().index.perComic;
    if (recent.isEmpty) return const SizedBox.shrink();
    final bookmarks = context.watch<BookmarkCubit>().state;

    _ContinueCard card(ReadHistory latest, {bool twoLineTitle = false}) =>
        _ContinueCard(
          latest: latest,
          twoLineTitle: twoLineTitle,
          bookmarked: bookmarks
              .where((b) => b.slug == latest.comicSlug)
              .firstOrNull
              ?.comicDetails,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(label: AppText.t.continueReading),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DotSpace.s4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (recent.length < 2 ||
                  constraints.maxWidth < DotSize.splitMinWidth) {
                return card(recent.first.latestHistory);
              }
              // Both titles take two lines, so the cards match in height
              // whatever each title wraps to. (IntrinsicHeight can't: the
              // card holds LayoutBuilders.)
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: DotSpace.s3,
                children: [
                  for (final item in recent.take(2))
                    Expanded(
                      child: card(item.latestHistory, twoLineTitle: true),
                    ),
                ],
              );
            },
          ),
        ),
        // Part of this section: no gap above New Series without history.
        const SizedBox(height: DotSpace.s5),
      ],
    );
  }
}

/// One comic's card: cover, type, title and the chapter it resumes at.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.latest,
    required this.bookmarked,
    required this.twoLineTitle,
  });

  final ReadHistory latest;

  /// Keeps two lines for the title even when it fits on one, so cards side
  /// by side are the same height.
  final bool twoLineTitle;

  /// The comic's bookmarked details, when it is bookmarked.
  final ComicDetails? bookmarked;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final bookmarked = this.bookmarked;
    // History keeps the details from when the chapter was read; a bookmark
    // refresh only updates the bookmark. Chapter lists only grow, so the
    // longer one knows about new chapters.
    final details =
        bookmarked != null &&
            bookmarked.chapters.length > latest.comicDetails.chapters.length
        ? bookmarked
        : latest.comicDetails;
    // The bookmark's cover is the newer one: covers on presigned URLs
    // expire, and a refresh only updates the bookmark.
    final cover = bookmarked?.coverImg ?? details.coverImg;
    final progress = ReadProgress.of(details, latest.chapterNumber);
    final heroTag = CoverHeroTag(context, cover);
    final resume = ResumeChapter.of(latest, details.chapters);

    return Pressable(
      semanticLabel: '${AppText.t.continueReading} ${details.title}',
      onTap: () => ComicDetailsScreen.open(
        context,
        slug: latest.comicSlug,
        title: details.title,
        cover: cover,
        heroTag: heroTag,
      ),
      child: _HoverPanel(
        child: Row(
          children: [
            SizedBox(
              width: 84,
              child: CoverHero(
                tag: heroTag,
                child: ComicCover(imageUrl: cover),
              ),
            ),
            const SizedBox(width: DotSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // "-" is what a source without one maps to;
                    // imported files have neither.
                    (LocalSource.isLocalKey(ComicKey.sourceOf(latest.comicSlug))
                            ? [AppText.t.onThisDevice]
                            : [
                                if (details.type != '-') details.type,
                                if (details.status != '-') details.status,
                              ])
                        .join(' · ')
                        .toUpperCase(),
                    style: DotlineText.label.copyWith(color: c.inkFaint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DotSpace.s2),
                  Stack(
                    children: [
                      // Two empty lines in the title's style set the height.
                      if (twoLineTitle)
                        ExcludeSemantics(
                          child: Text('\n', style: DotlineText.headline),
                        ),
                      Text(
                        details.title,
                        style: DotlineText.headline.copyWith(color: c.ink),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: DotSpace.s3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        // The chapter Continue reading opens.
                        resume.isNext
                            ? '${AppText.t.nextChapter.toUpperCase()} CH. '
                            : 'CH. ',
                        style: DotlineText.data.copyWith(color: c.inkFaint),
                      ),
                      Flexible(
                        child: Text(
                          resume.number,
                          style: DotlineText.stat.copyWith(
                            fontSize: 28,
                            color: c.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        ' / ${progress.latestNumber}',
                        style: DotlineText.data.copyWith(color: c.inkFaint),
                      ),
                    ],
                  ),
                  const SizedBox(height: DotSpace.s2),
                  DotMeter(
                    value: progress.position,
                    total: progress.total,
                    dots: 22,
                    gap: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card's `surface` panel, `surfaceRaised` under a mouse. Too wide to
/// grow like the covers do.
class _HoverPanel extends StatefulWidget {
  const _HoverPanel({required this.child});

  final Widget child;

  @override
  State<_HoverPanel> createState() => _HoverPanelState();
}

class _HoverPanelState extends State<_HoverPanel> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: DotMotion.press,
        padding: const EdgeInsets.all(DotSpace.s4),
        decoration: BoxDecoration(
          color: _hovered ? c.surfaceRaised : c.surface,
          borderRadius: BorderRadius.circular(DotRadius.l),
        ),
        child: widget.child,
      ),
    );
  }
}
