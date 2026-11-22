import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';

/// Languages to translate into: the English name sent to the model, and
/// the name in the language itself.
const translateLanguages = <(String, String)>[
  ('English', 'English'),
  ('Indonesian', 'Bahasa Indonesia'),
  ('Malay', 'Bahasa Melayu'),
  ('Javanese', 'Basa Jawa'),
  ('Sundanese', 'Basa Sunda'),
  ('Filipino', 'Filipino'),
  ('Vietnamese', 'Tiếng Việt'),
  ('Thai', 'ไทย'),
  ('Spanish', 'Español'),
  ('Portuguese', 'Português'),
  ('French', 'Français'),
  ('German', 'Deutsch'),
  ('Italian', 'Italiano'),
  ('Russian', 'Русский'),
  ('Turkish', 'Türkçe'),
  ('Arabic', 'العربية'),
  ('Hindi', 'हिन्दी'),
  ('Chinese (Simplified)', '简体中文'),
  ('Chinese (Traditional)', '繁體中文'),
  ('Japanese', '日本語'),
  ('Korean', '한국어'),
];

/// Field-like dropdown for the target language. [value] is an English name
/// from [translateLanguages] (or one typed in an older version), or empty
/// for the app's language, shown as [appLanguage].
class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({
    super.key,
    required this.value,
    required this.appLanguage,
    required this.onChanged,
  });

  final String value;

  /// The app's language in English, used when [value] is empty.
  final String appLanguage;
  final ValueChanged<String> onChanged;

  String _label(String english) {
    for (final (name, native) in translateLanguages) {
      if (name == english) return name == native ? name : '$name · $native';
    }
    return english;
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final options = <(String, String)>[
      ('', '${AppText.t.translateAppLanguage} · $appLanguage'),
      for (final (name, _) in translateLanguages) (name, _label(name)),
      // A language set before the list existed stays choosable.
      if (value.isNotEmpty && !translateLanguages.any((l) => l.$1 == value))
        (value, value),
    ];
    final current = options.firstWhere(
      (o) => o.$1 == value,
      orElse: () => options.first,
    );

    return LayoutBuilder(
      builder: (context, constraints) => MenuAnchor(
        alignmentOffset: const Offset(0, DotSpace.s1),
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          fixedSize: WidgetStatePropertyAll(
            Size.fromWidth(constraints.maxWidth),
          ),
          maximumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 320)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DotRadius.m),
              side: BorderSide(color: c.line),
            ),
          ),
        ),
        menuChildren: [
          for (final (id, label) in options)
            MenuItemButton(
              onPressed: () => onChanged(id),
              style: ButtonStyle(
                minimumSize: WidgetStatePropertyAll(
                  Size(constraints.maxWidth, 48),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: DotSpace.s4),
                ),
                overlayColor: WidgetStatePropertyAll(c.surfaceRaised),
                splashFactory: NoSplash.splashFactory,
              ),
              trailingIcon: id == current.$1
                  ? Icon(LucideIcons300.check, size: 18, color: c.ink)
                  : null,
              child: Text(
                label,
                style: DotlineText.body.copyWith(color: c.ink),
              ),
            ),
        ],
        builder: (context, controller, _) => Pressable(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: DotSpace.s3),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    current.$2,
                    style: DotlineText.body.copyWith(color: c.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  controller.isOpen
                      ? LucideIcons300.chevronUp
                      : LucideIcons300.chevronDown,
                  size: 18,
                  color: c.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
