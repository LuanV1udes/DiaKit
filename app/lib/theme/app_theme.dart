import 'package:flutter/material.dart';

import 'tokens.dart';

/// Monta o [ThemeData] das duas variantes a partir dos tokens em [DiaKitColors].
///
/// O visual das telas vem dos tokens, não dos defaults do Material: aqui só
/// alinhamos o que o framework desenha por conta própria (fundo, cor de texto
/// padrão, seleção, ripple) para que nada destoe do handoff.
abstract final class AppTheme {
  static ThemeData get light => _build(DiaKitColors.light, Brightness.light);

  static ThemeData get dark => _build(DiaKitColors.dark, Brightness.dark);

  static ThemeData _build(DiaKitColors c, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    return base.copyWith(
      extensions: [c],
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.divider,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.accent,
        brightness: brightness,
      ).copyWith(
        surface: c.bg,
        onSurface: c.text,
        primary: c.accent,
        outline: c.divider,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'JosefinSans',
        bodyColor: c.text,
        displayColor: c.text,
      ),
      iconTheme: IconThemeData(color: c.text, size: 20),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      // O sistema não usa ondas de ripple: os toques respondem com o mesmo
      // color-mix discreto de hover/active dos botões.
      splashFactory: InkSparkle.splashFactory,
      highlightColor: c.text.withValues(alpha: 0.05),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.3),
        selectionHandleColor: c.accent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.divider,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.text,
        contentTextStyle: AppText.bodySm.copyWith(color: c.bg),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }
}
