import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/core/presentation/widgets/dotline/dotline.dart';
import 'package:yoru/core/theme/dotline_colors.dart';
import 'package:yoru/core/theme/dotline_text.dart';
import 'package:yoru/core/theme/dotline_tokens.dart';
import 'package:yoru/features/settings/domain/entities/app_settings.dart';
import 'package:yoru/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:yoru/features/translate/domain/entities/translator_config.dart';
import 'package:yoru/core/utils/utils.dart';
import 'package:yoru/features/translate/presentation/translate_font.dart';
import 'package:yoru/features/translate/presentation/widgets/language_dropdown.dart';

/// An OpenAI-compatible server the screen can fill in.
typedef TranslatePreset = ({String name, String url, bool needsKey});

const translatePresets = <TranslatePreset>[
  (name: 'OpenAI', url: 'https://api.openai.com/v1', needsKey: true),
  (
    name: 'Gemini',
    url: 'https://generativelanguage.googleapis.com/v1beta/openai',
    needsKey: true,
  ),
  (name: 'OpenRouter', url: 'https://openrouter.ai/api/v1', needsKey: true),
  (name: 'Claude', url: 'https://api.anthropic.com/v1', needsKey: true),
  // Only its vision models read images (e.g. deepseek-v4-flash-vision-exp).
  (name: 'DeepSeek', url: 'https://api.deepseek.com/v1', needsKey: true),
  (name: 'Ollama', url: 'http://localhost:11434/v1', needsKey: false),
  (name: 'LM Studio', url: 'http://localhost:1234/v1', needsKey: false),
];

/// The translation setting as shown in More: the model (on the device or
/// the server's), or "Not set up".
String translateSettingLabel(AppSettings s) =>
    switch (TranslatorConfig.configured(s)) {
      final config? when config.mlKit => 'ML Kit',
      final config? => config.model,
      null => AppText.t.translateNotSet,
    };

/// More → Translation → Translate pages: server, key, model, language and
/// lettering. Translation itself is turned on in the reader's menu.
class TranslateSettingsScreen extends StatefulWidget {
  const TranslateSettingsScreen({super.key});

  /// Completes with true when a server and model were saved.
  static Future<bool?> open(BuildContext context) => Navigator.of(context)
      .push<bool>(
        MaterialPageRoute(builder: (_) => const TranslateSettingsScreen()),
      );

  @override
  State<TranslateSettingsScreen> createState() =>
      _TranslateSettingsScreenState();
}

class _TranslateSettingsScreenState extends State<TranslateSettingsScreen> {
  late final TextEditingController _url;
  late final TextEditingController _key;
  late final TextEditingController _model;
  late String _language;
  late final TextEditingController _notes;
  bool _showKey = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsCubit>().state;
    _url = TextEditingController(text: s.translateBaseUrl);
    _key = TextEditingController(text: s.translateApiKey);
    _model = TextEditingController(text: s.translateModel);
    _language = s.translateLanguage;
    _notes = TextEditingController(text: s.translateNotes);
  }

  @override
  void dispose() {
    _url.dispose();
    _key.dispose();
    _model.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Saves the fields and closes. A server without a model (or the other
  /// way round) is not saved; both empty turns translation off.
  void _save() {
    final url = TranslatorConfig.normalizeBaseUrl(_url.text);
    final model = _model.text.trim();
    if (url.isEmpty != model.isEmpty) {
      setState(() => _error = AppText.t.translateMissing);
      return;
    }
    context.read<SettingsCubit>().update(
      (s) => s.copyWith(
        translateBaseUrl: url,
        translateApiKey: _key.text.trim(),
        translateModel: model,
        translateLanguage: _language,
        translateNotes: _notes.text.trim(),
      ),
    );
    Navigator.of(context).pop(url.isNotEmpty);
  }

  /// Picks a font file to letter with; the previous import is deleted.
  Future<void> _importFont() async {
    final cubit = context.read<SettingsCubit>();
    final String? path;
    try {
      path = await importTranslateFont();
    } on FormatException {
      if (mounted) {
        showSnackBar(context: context, message: AppText.t.translateFontInvalid);
      }
      return;
    }
    if (path == null) return;
    final old = cubit.state.translateFontPath;
    if (await translateFontFamily(path) == null) {
      await deleteTranslateFont(path);
      if (mounted) {
        showSnackBar(context: context, message: AppText.t.translateFontInvalid);
      }
      return;
    }
    await cubit.update((s) => s.copyWith(translateFontPath: path!));
    await deleteTranslateFont(old);
  }

  /// Letters with a bundled font; an imported file is deleted.
  Future<void> _useBuiltinFont(String setting) async {
    final cubit = context.read<SettingsCubit>();
    final old = cubit.state.translateFontPath;
    if (old == setting) return;
    await cubit.update((s) => s.copyWith(translateFontPath: setting));
    await deleteTranslateFont(old);
  }

  @override
  Widget build(BuildContext context) {
    final c = Dotline.of(context);
    final engine = context.select((SettingsCubit s) => s.state.translateEngine);
    final mlKitSupported = Platform.isAndroid || Platform.isIOS;
    final mlKit = mlKitSupported && engine == 'mlkit';
    final scriptSetting = context.select(
      (SettingsCubit s) => s.state.translateScript,
    );
    final (uppercase, fontPath) = context.select(
      (SettingsCubit s) =>
          (s.state.translateUppercase, s.state.translateFontPath),
    );
    void setUppercase(bool on) => context.read<SettingsCubit>().update(
      (s) => s.copyWith(translateUppercase: on),
    );
    final style = DotlineText.body.copyWith(color: c.ink);

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: DotSpace.s4, bottom: DotSpace.s2),
      child: Text(
        text.toUpperCase(),
        style: DotlineText.label.copyWith(color: c.inkFaint),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Outside the scroll view so the title stays put.
            DotTopBar(title: AppText.t.translatePages),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => ListView(
                  padding: contentInset(constraints.maxWidth).add(
                    EdgeInsets.fromLTRB(
                      DotSpace.s4,
                      0,
                      DotSpace.s4,
                      DotSpace.s6 + MediaQuery.paddingOf(context).bottom,
                    ),
                  ),
                  children: [
                    Text(
                      AppText.t.translatePagesDescription,
                      style: DotlineText.bodyS.copyWith(color: c.inkMuted),
                    ),
                    if (mlKitSupported) ...[
                      label(AppText.t.translateEngine),
                      SegmentedControl<String>(
                        selected: mlKit ? 'mlkit' : 'api',
                        onChanged: (engine) => context
                            .read<SettingsCubit>()
                            .update((s) => s.copyWith(translateEngine: engine)),
                        segments: [
                          Segment(
                            value: 'api',
                            label: AppText.t.translateEngineServer,
                          ),
                          const Segment(value: 'mlkit', label: 'ML Kit'),
                        ],
                      ),
                    ],
                    if (mlKit) ...[
                      const SizedBox(height: DotSpace.s3),
                      Text(
                        AppText.t.translateMlKitHint,
                        style: DotlineText.bodyS.copyWith(color: c.inkFaint),
                      ),
                    ] else ...[
                      label(AppText.t.translateServer),
                      Wrap(
                        spacing: DotSpace.s2,
                        runSpacing: DotSpace.s2,
                        children: [
                          for (final p in translatePresets)
                            DotChip(
                              label: p.name,
                              selected:
                                  TranslatorConfig.normalizeBaseUrl(
                                    _url.text,
                                  ) ==
                                  p.url,
                              onTap: () => setState(() {
                                _url.text = p.url;
                                _error = null;
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: DotSpace.s3),
                      TextField(
                        controller: _url,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        style: style,
                        decoration: InputDecoration(
                          hintText: 'https://…/v1',
                          errorText: _error,
                        ),
                        onChanged: (_) => setState(() => _error = null),
                      ),
                      label(AppText.t.translateApiKey),
                      TextField(
                        controller: _key,
                        autocorrect: false,
                        enableSuggestions: false,
                        obscureText: !_showKey,
                        style: style,
                        decoration: InputDecoration(
                          hintText: AppText.t.translateApiKeyHint,
                          suffixIcon: IconButton(
                            tooltip: AppText.t.translateShowKey,
                            icon: Icon(
                              _showKey
                                  ? LucideIcons300.eyeOff
                                  : LucideIcons300.eye,
                              color: c.inkMuted,
                            ),
                            onPressed: () =>
                                setState(() => _showKey = !_showKey),
                          ),
                        ),
                      ),
                      label(AppText.t.translateModel),
                      TextField(
                        controller: _model,
                        autocorrect: false,
                        style: style,
                        decoration: InputDecoration(
                          hintText: AppText.t.translateModelHint,
                        ),
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                      ),
                    ],
                    label(AppText.t.translateScript),
                    Wrap(
                      spacing: DotSpace.s2,
                      runSpacing: DotSpace.s2,
                      children: [
                        for (final (setting, name) in [
                          ('auto', AppText.t.translateScriptAuto),
                          (OcrScript.cjk.name, AppText.t.translateScriptCjk),
                          (
                            OcrScript.korean.name,
                            AppText.t.translateScriptKorean,
                          ),
                          (
                            OcrScript.english.name,
                            AppText.t.translateScriptEnglish,
                          ),
                          (
                            OcrScript.latin.name,
                            AppText.t.translateScriptLatin,
                          ),
                        ])
                          DotChip(
                            label: name,
                            selected: scriptSetting == setting,
                            onTap: () => context.read<SettingsCubit>().update(
                              (s) => s.copyWith(translateScript: setting),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: DotSpace.s2),
                    Text(
                      AppText.t.translateScriptHint,
                      style: DotlineText.bodyS.copyWith(color: c.inkFaint),
                    ),
                    label(AppText.t.translateLanguage),
                    LanguageDropdown(
                      value: _language,
                      appLanguage: TranslatorConfig.fromSettings(
                        context.read<SettingsCubit>().state.copyWith(
                          translateLanguage: '',
                        ),
                      ).language,
                      onChanged: (l) => setState(() => _language = l),
                    ),
                    // ML Kit translates the text as it is: no notes.
                    if (!mlKit) ...[
                      label(AppText.t.translateNotes),
                      TextField(
                        controller: _notes,
                        style: style,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: AppText.t.translateNotesHint,
                        ),
                      ),
                    ],
                    label(AppText.t.translateLettering),
                    ListGroup(
                      children: [
                        ListRow(
                          title: AppText.t.translateUppercase,
                          subtitle: AppText.t.translateUppercaseHint,
                          trailing: DotSwitch(
                            value: uppercase,
                            semanticLabel: AppText.t.translateUppercase,
                            onChanged: setUppercase,
                          ),
                          onTap: () => setUppercase(!uppercase),
                        ),
                      ],
                    ),
                    label(AppText.t.translateFont),
                    Wrap(
                      spacing: DotSpace.s2,
                      runSpacing: DotSpace.s2,
                      children: [
                        for (final (setting, _, name) in builtinTranslateFonts)
                          DotChip(
                            label: name,
                            selected: fontPath == setting,
                            onTap: () => _useBuiltinFont(setting),
                          ),
                        if (!isBuiltinTranslateFont(fontPath))
                          DotChip(
                            label: translateFontName(fontPath),
                            selected: true,
                            onTap: _importFont,
                          ),
                        DotChip(
                          label: AppText.t.translateFontImport,
                          trailing: LucideIcons300.upload,
                          onTap: _importFont,
                        ),
                      ],
                    ),
                    const SizedBox(height: DotSpace.s2),
                    Text(
                      AppText.t.translateFontHint,
                      style: DotlineText.bodyS.copyWith(color: c.inkFaint),
                    ),
                    const SizedBox(height: DotSpace.s4),
                    DotButton(
                      label: AppText.t.save,
                      leading: LucideIcons300.check,
                      onTap: _save,
                    ),
                    const SizedBox(height: DotSpace.s4),
                    Text(
                      AppText.t.translatePrivacy,
                      style: DotlineText.bodyS.copyWith(color: c.inkFaint),
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
