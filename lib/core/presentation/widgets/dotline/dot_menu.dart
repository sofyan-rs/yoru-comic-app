import 'package:yoru/core/presentation/widgets/dotline/round_icon_button.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

class DotMenuItem {
  const DotMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
}

/// Round ⋮ button that opens a `surface` menu (at least [width] wide, wider
/// for a long label, as wide as the screen allows) with hairlines
/// between rows, its right edge under the button's (the buttons sit at the
/// top right, so the menu keeps the screen's margin). The trigger turns
/// `surfaceRaised` while open.
class DotMenuButton extends StatelessWidget {
  const DotMenuButton({
    super.key,
    required this.items,
    this.semanticLabel = 'Menu',
    this.iconSize = DotSize.icon,
    this.onOpen,
    this.onClose,
  });

  final List<DotMenuItem> items;
  final String semanticLabel;
  final double iconSize;

  /// Called when the menu opens and closes, e.g. to hide what would cover
  /// it (a Linux web view, which Flutter cannot draw over).
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  static const width = 224.0;

  /// Room in a row besides its label: the side padding, the icon and the
  /// gap after it, and a little to spare.
  static const _rowChrome = DotSpace.s4 * 2 + DotSize.iconMenu + 12 + 8;

  /// Wide enough for the longest label on one line ("Terjemahkan ulang
  /// chapter" does not fit [width]), within the screen's margins.
  double _menuWidth(BuildContext context) {
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    );
    var widest = 0.0;
    for (final item in items) {
      painter
        ..text = TextSpan(text: item.label, style: DotlineText.body)
        ..layout();
      if (painter.width > widest) widest = painter.width;
    }
    painter.dispose();
    final most = MediaQuery.sizeOf(context).width - DotSpace.s4 * 2;
    return (widest + _rowChrome).clamp(width, most < width ? width : most);
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final menuWidth = _menuWidth(context);
    return MenuAnchor(
      onOpen: onOpen,
      onClose: onClose,
      alignmentOffset: Offset(-(menuWidth - DotSize.touchTarget), DotSpace.s2),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        fixedSize: WidgetStatePropertyAll(Size.fromWidth(menuWidth)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DotRadius.m),
            side: BorderSide(color: c.line),
          ),
        ),
      ),
      menuChildren: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(),
          _DotMenuRow(item: items[i], width: menuWidth),
        ],
      ],
      builder: (context, controller, _) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: controller.isOpen
              ? [shadowFloat(Theme.of(context).brightness)]
              : null,
        ),
        child: RoundIconButton(
          icon: LucideIcons300.ellipsisVertical,
          semanticLabel: semanticLabel,
          iconSize: iconSize,
          background: controller.isOpen ? c.surfaceRaised : null,
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }
}

class _DotMenuRow extends StatelessWidget {
  const _DotMenuRow({required this.item, required this.width});

  final DotMenuItem item;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final color = item.destructive ? c.accentText : c.ink;
    return MenuItemButton(
      onPressed: item.onTap,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(width, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: DotSpace.s4),
        ),
        overlayColor: WidgetStatePropertyAll(c.surfaceRaised),
        splashFactory: NoSplash.splashFactory,
      ),
      leadingIcon: Icon(item.icon, size: DotSize.iconMenu, color: color),
      child: Text(
        item.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: DotlineText.body.copyWith(color: color),
      ),
    );
  }
}
