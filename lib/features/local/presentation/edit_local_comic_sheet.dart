import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/di/injection.dart';
import 'package:yoru/core/domain/entities/comic_details.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/source/comic_key.dart';
import 'package:yoru/core/source/extension_manager.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:yoru/core/utils/utils.dart';

/// Edits an imported comic's title, author, synopsis, genres and cover.
/// True when something changed, so the caller loads the comic again.
Future<bool> showEditLocalComicSheet(
  BuildContext context, {
  required String comicKey,
  required ComicDetails details,
}) async =>
    await showDotSheet<bool>(
      context: context,
      builder: (_) => _EditSheet(comicKey: comicKey, details: details),
    ) ??
    false;

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.comicKey, required this.details});

  final String comicKey;
  final ComicDetails details;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final _title = TextEditingController(text: widget.details.title);
  late final _author = TextEditingController(
    text: _orEmpty(widget.details.author),
  );
  late final _synopsis = TextEditingController(
    text: _orEmpty(widget.details.synopsis),
  );
  late final _genres = TextEditingController(
    text: [for (final g in widget.details.genres) g.name].join(', '),
  );
  var _saving = false;

  /// Placeholders the entity uses for a missing value.
  static String _orEmpty(String? value) =>
      value == null || value == '-' ? '' : value;

  String get _slug => ComicKey.slugOf(widget.comicKey);

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _synopsis.dispose();
    _genres.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await getIt<ExtensionManager>().local.edit(
        _slug,
        title: _title.text.trim().isEmpty ? widget.details.title : _title.text,
        author: _author.text,
        synopsis: _synopsis.text,
        genres: _genres.text.split(','),
      );
      if (!mounted) return;
      showSnackBar(context: context, message: AppText.t.detailsSaved);
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Editing ${widget.comicKey} failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      showSnackBar(context: context, message: AppText.t.saveFailed);
    }
  }

  /// A picked image, or null for the first page again.
  Future<void> _setCover({required bool pick}) async {
    String? path;
    if (pick) {
      final files = await FilePicker.pickFiles(
        dialogTitle: AppText.t.chooseCoverImage,
        type: FileType.image,
      );
      path = files.firstOrNull?.path;
      if (path == null) return;
    }
    try {
      await getIt<ExtensionManager>().local.setCover(_slug, path);
      if (!mounted) return;
      showSnackBar(context: context, message: AppText.t.coverChanged);
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Cover of ${widget.comicKey} failed: $e');
      if (mounted) {
        showSnackBar(context: context, message: AppText.t.saveFailed);
      }
    } finally {
      if (pick) FilePicker.clearTemporaryFiles().ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final style = DotlineText.body.copyWith(color: c.ink);
    Widget field(
      TextEditingController controller,
      String label, {
      String? hint,
      int maxLines = 1,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: DotSpace.s3),
      child: TextField(
        controller: controller,
        style: style,
        minLines: 1,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActionSheetHeader(
          icon: LucideIcons300.pencil,
          title: AppText.t.editDetails,
        ),
        const SizedBox(height: DotSpace.s4),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                field(_title, AppText.t.comicTitle),
                field(_author, AppText.t.comicAuthor),
                field(_synopsis, AppText.t.synopsis, maxLines: 6),
                field(
                  _genres,
                  AppText.t.comicGenres,
                  hint: AppText.t.comicGenresHint,
                ),
                const SizedBox(height: DotSpace.s2),
                Text(
                  AppText.t.coverLabel,
                  style: DotlineText.label.copyWith(color: c.inkFaint),
                ),
                const SizedBox(height: DotSpace.s2),
                Row(
                  children: [
                    Expanded(
                      child: DotButton.outline(
                        label: AppText.t.chooseCoverImage,
                        onTap: () => _setCover(pick: true),
                      ),
                    ),
                    const SizedBox(width: DotSpace.s3),
                    Expanded(
                      child: DotButton.outline(
                        label: AppText.t.useFirstPage,
                        onTap: () => _setCover(pick: false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DotSpace.s5),
        DotButton(label: AppText.t.save, onTap: _saving ? null : _save),
      ],
    );
  }
}
