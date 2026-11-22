import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yoru/core/assets/fonts.gen.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/di/injection.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:yoru/core/utils/utils.dart';
import 'package:yoru/features/translate/domain/entities/page_translation.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';
import 'package:yoru/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:yoru/features/translate/domain/usecases/translate_page.dart';
import 'package:yoru/features/translate/presentation/translate_font.dart';

/// A shown chapter page ([child]) with its translation laid over it: each
/// block a white box with the translated text, placed where the model
/// found the original. While it runs, or when it failed, a small pill sits
/// at the page's top right; tapping a failed one tries again.
///
/// [child] is the page image as laid out with [fit] and [alignment], so
/// the blocks follow the image inside its box (letterboxed when fitted to
/// height). Without a [config] it is just [child].
class TranslatedPage extends StatefulWidget {
  const TranslatedPage({
    super.key,
    required this.pageId,
    required this.readImage,
    required this.config,
    required this.fit,
    required this.alignment,
    required this.child,
  });

  /// URL or file path of the page; the cache key.
  final String pageId;
  final Future<Uint8List> Function() readImage;
  final TranslatorConfig? config;
  final BoxFit fit;
  final Alignment alignment;
  final Widget child;

  @override
  State<TranslatedPage> createState() => _TranslatedPageState();
}

enum _Status { idle, running, done, failed }

class _TranslatedPageState extends State<TranslatedPage> {
  _Status _status = _Status.idle;
  PageTranslation? _translation;
  String? _error;

  /// Bumped for every run, so a run the page no longer wants is ignored.
  int _run = 0;

  /// Finished translations of any page: one this page still waits for
  /// (its own run's answer lost, say, or started by the prefetch) is read
  /// from the cache.
  StreamSubscription<String>? _finished;

  @override
  void initState() {
    super.initState();
    _finished = getIt<TranslatePage>().completed.listen((page) {
      if (page == widget.pageId && _status != _Status.done) _start();
    });
    _start();
  }

  @override
  void dispose() {
    _finished?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(TranslatedPage old) {
    super.didUpdateWidget(old);
    if (old.config != widget.config || old.pageId != widget.pageId) _start();
  }

  Future<void> _start() async {
    final run = ++_run;
    final config = widget.config;
    _translation = null;
    _error = null;
    if (config == null) {
      _status = _Status.idle;
      return;
    }
    final translate = getIt<TranslatePage>();
    final stored = await translate.cached(widget.pageId, config);
    if (!mounted || run != _run) return;
    if (stored != null) {
      setState(() {
        _translation = stored;
        _status = _Status.done;
      });
      return;
    }
    setState(() => _status = _Status.running);
    if (_aspect == null) unawaited(_measure());
    final result = await translate((
      pageId: widget.pageId,
      readImage: widget.readImage,
      config: config,
    ));
    if (!mounted || run != _run) return;
    setState(() {
      result.fold(
        (failure) {
          _status = _Status.failed;
          _error = failure.message;
        },
        (translation) {
          _status = _Status.done;
          _translation = translation;
        },
      );
    });
  }

  /// Height over width of the page, read from its file's header while it
  /// is translated, to put the status pill on the page itself.
  double? _aspect;

  Future<void> _measure() async {
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(
        await widget.readImage(),
      );
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final aspect = descriptor.height / descriptor.width;
      descriptor.dispose();
      buffer.dispose();
      if (mounted) setState(() => _aspect = aspect);
    } catch (_) {
      // Unreadable here: the pill shows once the page's translation is in.
    }
  }

  /// Lettering family in use, and the font setting it came from.
  String _family = FontFamily.komikaHand;
  String? _fontPath;

  /// Switches to the font at [path] once it is registered.
  void _useFont(String path) {
    _fontPath = path;
    translateFontFamily(path).then((family) {
      if (!mounted || _fontPath != path) return;
      final next = family ?? FontFamily.komikaHand;
      if (next != _family) setState(() => _family = next);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.config == null) return widget.child;
    final (uppercase, fontPath) = context.select(
      (SettingsCubit s) =>
          (s.state.translateUppercase, s.state.translateFontPath),
    );
    if (fontPath != _fontPath) _useFont(fontPath);
    final translation = _translation;
    final aspect = translation?.aspect ?? _aspect;
    final busy = _status == _Status.running || _status == _Status.failed;
    return Stack(
      children: [
        widget.child,
        if (aspect != null &&
            (busy || (translation?.blocks.isNotEmpty ?? false)))
          Positioned.fill(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final box = constraints.biggest;
                final image = _imageRect(aspect, box);
                return Stack(
                  children: [
                    if (translation != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _blocks(
                            translation,
                            image,
                            uppercase: uppercase,
                          ),
                        ),
                      ),
                    if (busy)
                      // The page's top right, not the box's: a page fitted
                      // to height sits in the middle of a wider box.
                      Positioned(
                        top: image.top + DotSpace.s2,
                        right: box.width - image.right + DotSpace.s2,
                        child: _StatusPill(
                          failed: _status == _Status.failed,
                          error: _error,
                          onRetry: _start,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  /// Where an image [aspect] high per width is drawn inside [box].
  Rect _imageRect(double aspect, Size box) {
    final fitted = applyBoxFit(widget.fit, Size(1, aspect), box).destination;
    return widget.alignment.inscribe(fitted, Offset.zero & box);
  }

  Widget _blocks(
    PageTranslation translation,
    Rect image, {
    required bool uppercase,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    return Stack(
      children: [
        for (final b in translation.blocks)
          _bubble(
            b,
            uppercase ? b.text.toUpperCase() : b.text,
            image: image,
            scaler: scaler,
          ),
      ],
    );
  }

  /// [block] placed on the [image] rect, as [layoutBubble] lays it out.
  Widget _bubble(
    TextBlock block,
    String text, {
    required Rect image,
    required TextScaler scaler,
  }) {
    Rect onImage(double l, double t, double r, double b) => Rect.fromLTRB(
      image.left + l * image.width,
      image.top + t * image.height,
      image.left + r * image.width,
      image.top + b * image.height,
    );
    final layout = layoutBubble(
      onImage(block.left, block.top, block.right, block.bottom),
      text,
      balloon: switch (block.balloon) {
        final o? => onImage(o.left, o.top, o.right, o.bottom),
        null => null,
      },
      bounds: image,
      maxFontSize: bubbleMaxFontSize(image.width),
      scaler: scaler,
      fontFamily: _family,
    );
    return Positioned.fromRect(
      rect: layout.rect,
      child: _Bubble(
        text: text,
        layout: layout,
        scaler: scaler,
        fontFamily: _family,
      ),
    );
  }
}

/// Where a translated block is drawn and at what text size.
@visibleForTesting
typedef BubbleLayout = ({Rect rect, double fontSize, double padding});

/// Lettering of the translations: [fontFamily] (Komika Hand by default),
/// bold, black. It inherits nothing, so it is drawn exactly as measured
/// (the app theme's letter spacing would widen it and split words).
TextStyle bubbleTextStyle(double size, {String? fontFamily}) => TextStyle(
  inherit: false,
  fontFamily: fontFamily ?? FontFamily.komikaHand,
  // Letters a font lacks (accents, other scripts) come from these.
  fontFamilyFallback: const [FontFamily.comicNeue, FontFamily.geist],
  fontWeight: FontWeight.w700,
  fontSize: size,
  height: 1.1,
  letterSpacing: 0,
  wordSpacing: 0,
  color: const Color(0xFF000000),
  decoration: TextDecoration.none,
);

/// Largest lettering on a page shown [pageWidth] wide: about the size of
/// a comic's own lettering (2.8 % of the page width), 9 to 18.
double bubbleMaxFontSize(double pageWidth) =>
    (pageWidth * 0.028).clamp(_minFontSize, 18.0);

/// Smallest size worth reading; below it the bubble grows instead.
const _minFontSize = 9.0;

/// Lays out [text] over the model's box [area], which hugs the original
/// lettering, kept inside [bounds] (the image):
///
/// 1. The box a hair larger (so no letter edge shows), centred on its
///    [balloon] when the letters lie in one (models place balloons more
///    reliably), at the largest size up to [maxFontSize] whose wrapped
///    lines fit without splitting a word.
/// 2. When that is small (a tall, narrow column of vertical Japanese, say),
///    the inside of the balloon if the text is larger there: a white box
///    just around the text, also covering the original letters.
/// 3. When even [_minFontSize] fits nowhere, the box grown around its
///    centre just enough to hold the text.
@visibleForTesting
BubbleLayout layoutBubble(
  Rect area,
  String text, {
  required Rect bounds,
  Rect? balloon,
  TextScaler scaler = TextScaler.noScaling,
  String? fontFamily,
  double maxFontSize = 18,
}) {
  final inBalloon = balloon != null && balloon.contains(area.center);
  final centre = inBalloon ? balloon.center : area.center;
  final letters = Rect.fromCenter(
    center: centre,
    width: area.width + 4,
    height: area.height + 4,
  ).intersect(bounds);
  double padFor(Rect r) => (r.shortestSide * 0.04).clamp(1.5, 3.0);

  TextPainter paint(double size, double maxWidth) => TextPainter(
    text: TextSpan(
      text: text,
      style: bubbleTextStyle(size, fontFamily: fontFamily),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    textWidthBasis: TextWidthBasis.longestLine,
    textScaler: scaler,
  )..layout(maxWidth: max(maxWidth, 1));

  bool fits(Rect rect, double size) {
    final inner = rect.deflate(padFor(rect));
    if (inner.width <= 0 || inner.height <= 0) return false;
    final painter = paint(size, inner.width);
    final ok =
        painter.height <= inner.height &&
        painter.minIntrinsicWidth <= inner.width + 0.5;
    painter.dispose();
    return ok;
  }

  /// The largest size up to [maxFontSize] that fits [rect], or null.
  double? bestSize(Rect rect) {
    if (fits(rect, maxFontSize)) return maxFontSize;
    if (!fits(rect, _minFontSize)) return null;
    var lo = _minFontSize;
    var hi = maxFontSize;
    for (var i = 0; i < 8; i++) {
      final mid = (lo + hi) / 2;
      if (fits(rect, mid)) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  final inLetters = bestSize(letters);
  if (inLetters != null && inLetters >= maxFontSize * 0.8) {
    return (rect: letters, fontSize: inLetters, padding: padFor(letters));
  }

  if (inBalloon) {
    // Balloons are round: keep clear of the outline.
    final inside = balloon
        .deflate(balloon.shortestSide * 0.12)
        .intersect(bounds);
    final size = inside.isEmpty ? null : bestSize(inside);
    if (size != null && size > (inLetters ?? 0)) {
      final pad = padFor(letters);
      final painter = paint(size, inside.width - pad * 2);
      final around = Rect.fromCenter(
        center: inside.center,
        width: painter.width + pad * 2 + 1,
        height: painter.height + pad * 2,
      );
      painter.dispose();
      return (
        rect: around.expandToInclude(letters).intersect(bounds),
        fontSize: size,
        padding: pad,
      );
    }
  }

  if (inLetters != null) {
    return (rect: letters, fontSize: inLetters, padding: padFor(letters));
  }

  // Too small even at the smallest size: grow the box around its centre.
  final padding = padFor(letters);
  final painter = paint(_minFontSize, letters.width - padding * 2);
  final width = max(
    letters.width,
    max(painter.minIntrinsicWidth, painter.width) + padding * 2 + 1,
  );
  final measured = paint(_minFontSize, width - padding * 2);
  final height = max(letters.height, measured.height + padding * 2);
  painter.dispose();
  measured.dispose();
  var grown = Rect.fromCenter(
    center: letters.center,
    width: min(width, bounds.width),
    height: min(height, bounds.height),
  );
  grown = grown.shift(
    Offset(
      grown.left < bounds.left
          ? bounds.left - grown.left
          : grown.right > bounds.right
          ? bounds.right - grown.right
          : 0,
      grown.top < bounds.top
          ? bounds.top - grown.top
          : grown.bottom > bounds.bottom
          ? bounds.bottom - grown.bottom
          : 0,
    ),
  );
  return (rect: grown, fontSize: _minFontSize, padding: padding);
}

/// A rounded white bubble over the original lettering with the
/// translation in it, laid out by [layoutBubble].
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.layout,
    required this.scaler,
    required this.fontFamily,
  });

  final String text;
  final BubbleLayout layout;
  final TextScaler scaler;
  final String fontFamily;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFFFFFFF),
      // Rounded, hugging the lettering it covers.
      borderRadius: BorderRadius.circular(layout.rect.shortestSide * 0.3),
    ),
    child: Padding(
      padding: EdgeInsets.all(layout.padding),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          textScaler: scaler,
          overflow: TextOverflow.clip,
          style: bubbleTextStyle(layout.fontSize, fontFamily: fontFamily),
        ),
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.failed,
    required this.error,
    required this.onRetry,
  });

  final bool failed;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final pill = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DotSpace.s3,
        vertical: DotSpace.s2,
      ),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(DotRadius.pill),
        border: Border.all(color: c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (failed)
            Icon(
              LucideIcons300.rotateCw,
              size: DotSize.iconSmall,
              color: c.accent,
            )
          else
            const DotLoader(dots: 3),
          const SizedBox(width: DotSpace.s2),
          Text(
            (failed ? AppText.t.translateFailed : AppText.t.translating)
                .toUpperCase(),
            style: DotlineText.label.copyWith(color: c.ink),
          ),
        ],
      ),
    );
    if (!failed) return pill;
    return Tooltip(
      message: error ?? '',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRetry,
        onLongPress: error == null
            ? null
            : () => showSnackBar(context: context, message: error!),
        child: pill,
      ),
    );
  }
}
