import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/constants/variables.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:yoru/core/utils/utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// "About the app" sheet: version, description, and links to the developer
/// site and the Ko-fi support page.
class AppInfo extends StatefulWidget {
  const AppInfo({super.key});

  @override
  State<AppInfo> createState() => _AppInfoState();
}

class _AppInfoState extends State<AppInfo> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  Future<void> _openLink(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      showSnackBar(context: context, message: AppText.t.linkFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(
          icon: LucideIcons300.info,
          title: AppVariables.appName,
          subtitle: '${AppText.t.version} $_appVersion',
        ),
        const SizedBox(height: DotSpace.s4),
        Text(
          AppVariables.appDescription,
          style: DotlineText.body.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: DotSpace.s5),
        ListGroup(
          background: c.bg,
          children: [
            ListRow(
              icon: LucideIcons300.globe,
              title: AppText.t.website,
              subtitle: AppVariables.websiteLabel,
              onTap: () => _openLink(AppVariables.websiteLink),
            ),
            // Store policies restrict links to outside payments, so store
            // builds leave it out.
            if (!AppVariables.storeBuild)
              ListRow(
                icon: LucideIcons300.heart,
                title: AppText.t.giveSupport,
                subtitle: AppVariables.supportLabel,
                onTap: () => _openLink(AppVariables.supportLink),
              ),
          ],
        ),
      ],
    );
  }
}
