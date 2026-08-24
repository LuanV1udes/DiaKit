import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      const SnackBar(content: Text('Essa opção chega em uma próxima versão.')),
    );
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
    final isDesktop = context.isDesktop;
    final groupWidth = isDesktop ? 520.0 : double.infinity;

    return ListView(
      padding: isDesktop
          ? const EdgeInsets.fromLTRB(48, 40, 48, 40)
          : const EdgeInsets.fromLTRB(24, 24, 24, 12),
      children: [
        Text(
          'Perfil',
          style: (isDesktop ? AppText.h1Desktop : AppText.h2).copyWith(
            color: c.text,
          ),
        ),
        SizedBox(height: isDesktop ? 28 : 20),
        _Identity(isDesktop: isDesktop),
        SizedBox(height: isDesktop ? 32 : 28),
        Kicker('Preferências', bottom: isDesktop ? 10 : 8),
        ContentWidth(
          maxWidth: groupWidth,
          child: SettingsGroup(
            rows: [
              SettingsRow(
                icon: LucideIcons.bell,
                label: 'Notificações',
                onTap: _soon,
                dense: !isDesktop,
              ),
              SettingsRow(
                icon: LucideIcons.globe,
                label: 'Idioma',
                value: 'Português',
                onTap: _soon,
                dense: !isDesktop,
              ),
              // Fora do mockup, mas necessário: sem o endereço do serviço de
              // conversão o app não tem como converter nada.
              SettingsRow(
                icon: LucideIcons.settings,
                label: 'Servidor de conversão',
                value: Uri.tryParse(_serverUrl)?.authority ?? _serverUrl,
                onTap: _editServerUrl,
                dense: !isDesktop,
              ),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 28 : 24),
        Kicker('Suporte', bottom: isDesktop ? 10 : 8),
        ContentWidth(
          maxWidth: groupWidth,
          child: SettingsGroup(
            rows: [
              SettingsRow(
                icon: LucideIcons.circleHelp,
                label: 'Ajuda',
                onTap: _soon,
                dense: !isDesktop,
              ),
              SettingsRow(
                icon: LucideIcons.messageSquare,
                label: 'Enviar feedback',
                onTap: _soon,
                dense: !isDesktop,
              ),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 28 : 24),
        const Kicker('Sobre', bottom: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
          child: Text(
            'DiaKit · versão $kAppVersion',
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
              'Usuário DiaKit',
              style: AppText.h6.copyWith(
                fontSize: isDesktop ? 18 : 16,
                color: c.text,
              ),
            ),
            const SizedBox(height: 4),
            const AppTag('Conta gratuita', variant: AppTagVariant.outline),
          ],
        ),
      ],
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

    return AlertDialog(
      title: Text(
        'Servidor de conversão',
        style: AppText.h4.copyWith(color: c.text),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Endereço do serviço que converte os documentos. Por padrão, o '
            'backend do DiaKit rodando na própria máquina.',
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
          label: 'Cancelar',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          height: 40,
          textStyle: AppText.buttonSm,
        ),
        AppButton(
          label: 'Salvar',
          onPressed: _submit,
          height: 40,
          textStyle: AppText.buttonSm,
        ),
      ],
    );
  }
}
