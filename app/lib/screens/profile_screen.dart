import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/settings_store.dart';
import '../theme/layout.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/primitives.dart';
import '../widgets/rows.dart';

/// Telas 06 (mobile) e 17 (desktop) — Perfil / Configurações.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _settings = SettingsStore();
  String _serverUrl = SettingsStore.defaultServerUrl;

  @override
  void initState() {
    super.initState();
    _settings.serverUrl().then((url) {
      if (mounted) setState(() => _serverUrl = url);
    });
  }

  void _soon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.comingSoonMessage)),
    );
  }

  String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
    ThemeMode.system => l10n.themeSystem,
    ThemeMode.light => l10n.themeLight,
    ThemeMode.dark => l10n.themeDark,
  };

  Future<void> _pickThemeMode() async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => _ThemeModeDialog(current: themeModeNotifier.value),
    );
    if (selected == null) return;

    themeModeNotifier.value = selected;
    await _settings.setThemeMode(selected);
  }

  Future<void> _pickLocale() async {
    final selected = await showDialog<Locale>(
      context: context,
      builder: (context) => _LocaleDialog(current: localeNotifier.value),
    );
    if (selected == null) return;

    localeNotifier.value = selected;
    await _settings.setLocale(selected);
  }

  Future<void> _editServerUrl() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _ServerUrlDialog(initialValue: _serverUrl),
    );
    if (result == null) return;

    await _settings.setServerUrl(result);
    if (mounted) setState(() => _serverUrl = result);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = context.isDesktop;
    final groupWidth = isDesktop ? 520.0 : double.infinity;

    return ListView(
      padding: isDesktop
          ? const EdgeInsets.fromLTRB(48, 40, 48, 40)
          : const EdgeInsets.fromLTRB(24, 24, 24, 12),
      children: [
        Text(
          l10n.profileTitle,
          style: (isDesktop ? AppText.h1Desktop : AppText.h2).copyWith(
            color: c.text,
          ),
        ),
        SizedBox(height: isDesktop ? 28 : 20),
        _Identity(isDesktop: isDesktop),
        SizedBox(height: isDesktop ? 32 : 28),
        Kicker(l10n.preferencesKicker, bottom: isDesktop ? 10 : 8),
        ContentWidth(
          maxWidth: groupWidth,
          child: SettingsGroup(
            rows: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeNotifier,
                builder: (context, mode, _) => SettingsRow(
                  icon: LucideIcons.sunMoon,
                  label: l10n.appearanceLabel,
                  value: _themeModeLabel(l10n, mode),
                  onTap: _pickThemeMode,
                  dense: !isDesktop,
                ),
              ),
              SettingsRow(
                icon: LucideIcons.bell,
                label: l10n.notificationsLabel,
                onTap: _soon,
                dense: !isDesktop,
              ),
              ValueListenableBuilder<Locale>(
                valueListenable: localeNotifier,
                builder: (context, locale, _) => SettingsRow(
                  icon: LucideIcons.globe,
                  label: l10n.languageLabel,
                  value: locale.languageCode == 'en' ? 'English' : 'Português',
                  onTap: _pickLocale,
                  dense: !isDesktop,
                ),
              ),
              // Fora do mockup, mas necessário: sem o endereço do serviço de
              // conversão o app não tem como converter nada.
              SettingsRow(
                icon: LucideIcons.settings,
                label: l10n.serverLabel,
                value: Uri.tryParse(_serverUrl)?.authority ?? _serverUrl,
                onTap: _editServerUrl,
                dense: !isDesktop,
              ),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 28 : 24),
        Kicker(l10n.supportKicker, bottom: isDesktop ? 10 : 8),
        ContentWidth(
          maxWidth: groupWidth,
          child: SettingsGroup(
            rows: [
              SettingsRow(
                icon: LucideIcons.circleHelp,
                label: l10n.helpLabel,
                onTap: _soon,
                dense: !isDesktop,
              ),
              SettingsRow(
                icon: LucideIcons.messageSquare,
                label: l10n.sendFeedbackLabel,
                onTap: _soon,
                dense: !isDesktop,
              ),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 28 : 24),
        Kicker(l10n.aboutKicker, bottom: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
          child: Text(
            l10n.appVersionLabel(kAppVersion),
            style: AppText.caption.copyWith(color: c.neutral500),
          ),
        ),
      ],
    );
  }
}

/// Avatar, nome e o rótulo do plano.
class _Identity extends StatelessWidget {
  const _Identity({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;
    final size = isDesktop ? 64.0 : 56.0;

    return Row(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.surface,
            border: Border.all(color: c.divider),
          ),
          child: Icon(
            LucideIcons.user,
            size: isDesktop ? 28 : 26,
            color: c.neutral700,
          ),
        ),
        SizedBox(width: isDesktop ? 16 : 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.defaultUserName,
              style: AppText.h6.copyWith(
                fontSize: isDesktop ? 18 : 16,
                color: c.text,
              ),
            ),
            const SizedBox(height: 4),
            AppTag(l10n.freeAccountTag, variant: AppTagVariant.outline),
          ],
        ),
      ],
    );
  }
}

/// Diálogo de seleção do tema (claro/escuro/sistema) aberto pela linha
/// "Aparência". Tocar numa opção já a seleciona e fecha o diálogo.
class _ThemeModeDialog extends StatelessWidget {
  const _ThemeModeDialog({required this.current});

  final ThemeMode current;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;
    final options = [
      (mode: ThemeMode.system, icon: LucideIcons.monitor, label: l10n.themeSystem),
      (mode: ThemeMode.light, icon: LucideIcons.sun, label: l10n.themeLight),
      (mode: ThemeMode.dark, icon: LucideIcons.moon, label: l10n.themeDark),
    ];

    return AlertDialog(
      title: Text(l10n.appearanceLabel, style: AppText.h4.copyWith(color: c.text)),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            _SelectableOptionRow(
              icon: option.icon,
              label: option.label,
              selected: option.mode == current,
              onTap: () => Navigator.of(context).pop(option.mode),
            ),
        ],
      ),
    );
  }
}

/// Diálogo de seleção de idioma aberto pela linha "Idioma". O app nunca
/// segue o idioma do sistema, então as opções são só as línguas suportadas
/// -- e cada uma aparece no próprio idioma, não no idioma ativo no momento.
class _LocaleDialog extends StatelessWidget {
  const _LocaleDialog({required this.current});

  final Locale current;

  static const _options = [
    (locale: Locale('pt'), label: 'Português'),
    (locale: Locale('en'), label: 'English'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.languageLabel, style: AppText.h4.copyWith(color: c.text)),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in _options)
            _SelectableOptionRow(
              icon: LucideIcons.globe,
              label: option.label,
              selected: option.locale == current,
              onTap: () => Navigator.of(context).pop(option.locale),
            ),
        ],
      ),
    );
  }
}

/// Uma opção de rádio dos diálogos de Aparência e Idioma: ícone, rótulo e um
/// check à direita quando selecionada.
class _SelectableOptionRow extends StatelessWidget {
  const _SelectableOptionRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        hoverColor: c.text.withValues(alpha: 0.04),
        splashColor: c.text.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: selected ? c.accent : c.neutral700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppText.body.copyWith(
                    color: c.text,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected) Icon(LucideIcons.check, size: 18, color: c.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diálogo de edição do endereço do backend, no estilo `.dialog` do sistema.
class _ServerUrlDialog extends StatefulWidget {
  const _ServerUrlDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_ServerUrlDialog> createState() => _ServerUrlDialogState();
}

class _ServerUrlDialogState extends State<_ServerUrlDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.serverLabel, style: AppText.h4.copyWith(color: c.text)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.serverDialogDescription,
            style: AppText.bodySm.copyWith(color: c.neutral700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            onSubmitted: (_) => _submit(),
            style: AppText.body.copyWith(color: c.text),
            decoration: InputDecoration(
              hintText: SettingsStore.defaultServerUrl,
              hintStyle: AppText.body.copyWith(color: c.neutral500),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: BorderSide(color: c.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: BorderSide(color: c.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: BorderSide(color: c.accent),
              ),
            ),
          ),
        ],
      ),
      actions: [
        AppButton(
          label: l10n.cancelButton,
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          height: 40,
          textStyle: AppText.buttonSm,
        ),
        AppButton(
          label: l10n.saveButton,
          onPressed: _submit,
          height: 40,
          textStyle: AppText.buttonSm,
        ),
      ],
    );
  }
}
