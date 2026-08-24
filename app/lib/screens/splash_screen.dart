import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tokens.dart';
import '../widgets/app_button.dart';

/// Tela 01 — Splash / Onboarding.
///
/// O handoff não prevê versão desktop desta tela; em janelas largas o conteúdo
/// fica centralizado numa coluna da largura do mockup em vez de esticar.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: Center(child: _Illustration())),
                  Text('DiaKit', style: AppText.display.copyWith(color: c.text)),
                  const SizedBox(height: 10),
                  Text(
                    'Ferramentas essenciais para o seu dia a dia, direto do '
                    'bolso. Comece transformando seus documentos do Word, '
                    'Excel e PowerPoint em PDF prontos para imprimir.',
                    style: AppText.bodyLg.copyWith(color: c.neutral700),
                  ),
                  const SizedBox(height: 28),
                  const _PageDots(count: 3, active: 0),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Começar',
                    onPressed: onStart,
                    expand: true,
                    height: 48,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card de ilustração: documento → seta → documento com check.
class _Illustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return AspectRatio(
      aspectRatio: 1 / 0.9,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: c.divider),
          boxShadow: c.shadowSm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileText, size: 44, color: c.neutral700),
            const SizedBox(width: 18),
            Icon(LucideIcons.arrowRight, size: 22, color: c.accent),
            const SizedBox(width: 18),
            Icon(LucideIcons.fileCheck2, size: 44, color: c.accentStrong),
          ],
        ),
      ),
    );
  }
}

/// Indicador de página do onboarding: o passo ativo é uma barra mais larga.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Container(
            width: i == active ? 20 : 8,
            height: 4,
            decoration: BoxDecoration(
              color: i == active ? c.accent : c.divider,
              borderRadius: const BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ],
      ],
    );
  }
}
