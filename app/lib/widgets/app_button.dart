import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Variantes de `.btn` do design system.
///
/// Atenção: `.btn-primary` do sistema é **contornado**, não preenchido -- a cor
/// marsala aparece na borda e no texto, sobre fundo transparente.
enum AppButtonVariant {
  /// Texto e borda accent. Ação principal da tela.
  primary,

  /// Borda hairline, texto na cor de texto. Ação secundária.
  secondary,

  /// Só texto accent, sem borda. Ação terciária / link.
  ghost,
}

/// Botão do design system (`.btn` + variantes).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expand = false,
    this.height = 48,
    this.textStyle,
    this.horizontalPadding,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Ícone Lucide opcional à esquerda do rótulo.
  final IconData? icon;

  /// `.btn-block` -- ocupa toda a largura disponível.
  final bool expand;

  final double height;
  final TextStyle? textStyle;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final enabled = onPressed != null;

    final (Color foreground, Color? border, Color overlayBase) = switch (variant) {
      AppButtonVariant.primary => (c.accent, c.accent, c.accent),
      AppButtonVariant.secondary => (c.text, c.divider, c.text),
      AppButtonVariant.ghost => (c.accent, null, c.accent),
    };

    // hover/active do sistema: 12%/22% do accent, 7%/14% do texto.
    final (double hover, double pressed) = switch (variant) {
      AppButtonVariant.primary => (0.12, 0.22),
      AppButtonVariant.secondary => (0.07, 0.14),
      AppButtonVariant.ghost => (0.10, 0.18),
    };

    final padding =
        horizontalPadding ??
        (variant == AppButtonVariant.ghost ? AppSpace.s1 : AppSpace.s3 * 1.2);

    final style = TextButton.styleFrom(
      foregroundColor: foreground,
      backgroundColor: Colors.transparent,
      disabledForegroundColor: foreground,
      minimumSize: Size(expand ? double.infinity : 0, height),
      fixedSize: expand ? null : Size.fromHeight(height),
      padding: EdgeInsets.symmetric(horizontal: padding),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      side: BorderSide(color: border ?? Colors.transparent, width: 1),
      textStyle: textStyle ?? AppText.button,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return overlayBase.withValues(alpha: pressed);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return overlayBase.withValues(alpha: hover);
        }
        return null;
      }),
    );

    final button = TextButton(
      onPressed: onPressed,
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: (textStyle ?? AppText.button).fontSize! + 1),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (textStyle ?? AppText.button).copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );

    // `.btn:disabled { opacity: .45 }` -- desbota também a borda, não só o texto.
    final result = enabled ? button : Opacity(opacity: 0.45, child: button);
    return expand ? SizedBox(width: double.infinity, child: result) : result;
  }
}

/// `.btn-icon.btn-secondary` circular -- o avatar do header da Home.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 36,
    this.iconSize = 18,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        shape: CircleBorder(side: BorderSide(color: c.divider)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          hoverColor: c.text.withValues(alpha: 0.07),
          highlightColor: c.text.withValues(alpha: 0.14),
          splashColor: c.text.withValues(alpha: 0.14),
          child: Icon(icon, size: iconSize, color: c.text),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
