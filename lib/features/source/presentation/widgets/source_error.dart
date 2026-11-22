import 'package:yoru/features/local/presentation/local_import.dart';
import 'package:yoru/core/source/local/local_source.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/error/exceptions.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/source/extension_manager.dart';
import 'package:yoru/features/source/presentation/pages/extensions_screen.dart';
import 'package:yoru/features/source/presentation/pages/web_view_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';

/// Error state for a failed source call. A bot check ([Challenge]) offers
/// to pass it in the WebView, whose cookies the extension then reuses, and
/// retries when the WebView closes; no installed source leads to the
/// extensions; no imported comics, to importing some; anything else shows the message with a retry button.
class SourceError extends StatelessWidget {
  const SourceError({
    super.key,
    required this.message,
    required this.sourceId,
    required this.onRetry,
  });

  final String message;

  /// Extension that made the call; its cookie jar gets the WebView's
  /// cookies. Null when unknown, which disables the WebView offer.
  final String? sourceId;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (message == localEmptyMessage) {
      return EmptyState(
        icon: LucideIcons300.folderInput,
        title: AppText.t.noLocalComics,
        message: canImportFolders
            ? AppText.t.noLocalComicsHint
            : AppText.t.noLocalComicsHintFiles,
        actionLabel: AppText.t.importComics,
        onAction: () async {
          if (await importLocalComics(context)) onRetry();
        },
      );
    }
    if (message == noSourceMessage) {
      return EmptyState(
        icon: LucideIcons300.blocks,
        title: AppText.t.noSourceShort,
        message: AppText.t.noSourceHint,
        actionLabel: AppText.t.addSource,
        onAction: () async {
          await ExtensionsScreen.open(context, showAvailable: true);
          onRetry();
        },
      );
    }
    final url = Challenge.urlOf(message);
    final sourceId = this.sourceId;
    if (url == null || sourceId == null) {
      return EmptyState(
        icon: LucideIcons300.bug,
        title: AppText.t.error,
        message: message,
        actionLabel: AppText.t.retry,
        onAction: onRetry,
      );
    }
    return EmptyState(
      icon: LucideIcons300.shieldAlert,
      title: AppText.t.verificationNeeded,
      message: AppText.t.verificationNeededHint,
      actionLabel: AppText.t.verifyInWebView,
      onAction: () async {
        await WebViewScreen.open(context, sourceId: sourceId, url: url);
        onRetry();
      },
    );
  }
}
