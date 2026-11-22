import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:yoru/features/settings/domain/entities/app_settings.dart';
import 'package:yoru/features/settings/presentation/bloc/settings_cubit.dart';

/// Picks the language of the app's own text.
Future<void> showLanguageSheet(BuildContext context) => showDotSheet<void>(
  context: context,
  builder: (_) => const _LanguageSheet(),
);

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final current = context.select((SettingsCubit s) => s.state.language);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(
          icon: LucideIcons300.languages,
          title: AppText.t.appLanguage,
        ),
        const SizedBox(height: DotSpace.s4),
        ListGroup(
          background: c.bg,
          children: [
            for (final language in AppLanguage.values)
              ListRow(
                title: language.nativeName,
                showChevron: false,
                trailing: language == current
                    ? Icon(LucideIcons300.check, color: c.ink)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<SettingsCubit>().changeLanguage(language);
                },
              ),
          ],
        ),
      ],
    );
  }
}
