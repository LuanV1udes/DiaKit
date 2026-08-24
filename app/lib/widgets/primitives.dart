import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// `.kicker` -- rótulo de seção em caixa alta com tracking aberto.
class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.bottom = 0});

  final String text;

  /// Espaço abaixo do rótulo (o mockup varia entre 8 e 16px).
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Text(
        text.toUpperCase(),
        style: AppText.kicker.copyWith(color: context.c.neutral500),
      ),
    );
  }
}

/// Variantes de `.tag` usadas nas telas.
enum AppTagVariant {
  /// `.tag-accent` -- fundo tint, texto no degrau escuro. Estado concluído.
  accent,

  /// `.tag-outline` -- contorno accent. Estado de erro e rótulo de plano.
  outline,
}

/// `.tag` -- chip de estado.
class AppTag extends StatelessWidget {
  const AppTag(this.label, {super.key, this.variant = AppTagVariant.accent});

  final String label;
  final AppTagVariant variant;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isAccent = variant == AppTagVariant.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isAccent ? c.accentTint : Colors.transparent,
        borderRadius: AppRadius.tagAll,
        border: isAccent ? null : Border.all(color: c.accent),
      ),
      child: Text(
        label,
        style: AppText.tag.copyWith(
          color: isAccent ? c.accentOnTint : c.accent,
        ),
      ),
    );
  }
}

/// `.hr` -- régua de 1px na cor de divisor.
class Hairline extends StatelessWidget {
  const Hairline({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: context.c.divider);
  }
}

/// Limita a largura do conteúdo e o encosta à esquerda.
///
/// Os layouts desktop do handoff usam `max-width` em vez de esticar os cards.
/// Um `ConstrainedBox` sozinho não resolve: dentro de uma lista ele recebe
/// largura apertada e `enforce` faz a restrição de fora vencer -- por isso o
/// [Align], que afrouxa as constraints antes.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.maxWidth, required this.child});

  /// `double.infinity` deixa o filho ocupar tudo (é o caso do mobile).
  final double maxWidth;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (maxWidth == double.infinity) return child;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Card de conteúdo: contorno hairline (ou accent, quando em destaque) e
/// `--radius-lg`.
class OutlinedCard extends StatelessWidget {
  const OutlinedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.borderColor,
    this.elevated = false,
    this.onTap,
    this.borderRadius = AppRadius.lgAll,
    this.clipContent = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Por padrão usa o divisor; o card em destaque da Home usa o accent.
  final Color? borderColor;

  /// Aplica `--shadow-sm`.
  final bool elevated;

  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  /// Recorta os filhos no raio do card (grupos de linhas do Perfil).
  final bool clipContent;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? c.divider),
        boxShadow: elevated ? c.shadowSm : null,
        // O card do design é transparente, mas a sombra do Flutter é pintada
        // como um retângulo cheio atrás dele — sem um fundo opaco ela vazaria
        // por dentro do card.
        color: elevated ? c.bg : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        clipBehavior: clipContent ? Clip.antiAlias : Clip.none,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          hoverColor: onTap == null ? Colors.transparent : c.text.withValues(alpha: 0.04),
          splashColor: onTap == null ? Colors.transparent : c.text.withValues(alpha: 0.06),
          highlightColor: Colors.transparent,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
