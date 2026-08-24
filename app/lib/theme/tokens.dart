import 'package:flutter/material.dart';

/// Tokens de cor do design system do DiaKit (base "Classical", retunada com a
/// rampa marsala/avelã do handoff em `DiaKit document converter/`).
///
/// Exposto como [ThemeExtension] para que claro e escuro sejam a mesma
/// estrutura com valores diferentes -- e nenhuma tela precise de `if (isDark)`.
@immutable
class DiaKitColors extends ThemeExtension<DiaKitColors> {
  const DiaKitColors({
    required this.bg,
    required this.surface,
    required this.text,
    required this.divider,
    required this.neutral500,
    required this.neutral700,
    required this.accent,
    required this.accentTint,
    required this.accentStrong,
    required this.accentOnTint,
    required this.accent2,
    required this.shadow,
  });

  /// Fundo da tela (`--color-bg`).
  final Color bg;

  /// Superfície elevada: card de ilustração da Splash, avatar (`--color-surface`).
  final Color surface;

  /// Texto principal (`--color-text`).
  final Color text;

  /// Hairline de 1px entre linhas e contorno de cards (`--color-divider`).
  final Color divider;

  /// Texto/ícone terciário: metadados e legendas (`--color-neutral-500`).
  final Color neutral500;

  /// Texto/ícone secundário: parágrafos de apoio (`--color-neutral-700`).
  final Color neutral700;

  /// Marsala base -- borda do botão primário, indicadores (`--color-accent`).
  final Color accent;

  /// Tint de fundo do accent: chip de ícone, tag e item ativo da sidebar
  /// (`--color-accent-100`).
  final Color accentTint;

  /// Degrau escuro do accent: ícones e texto sobre o tint (`--color-accent-700`).
  final Color accentStrong;

  /// Texto sobre [accentTint] dentro das tags (`--color-accent-800`).
  ///
  /// No modo escuro o mockup não redefine `--color-accent-800`, o que deixaria a
  /// tag "Concluído" com texto da mesma cor do próprio fundo; aqui usamos o
  /// degrau claro (`--color-accent-700`) para manter o contraste.
  final Color accentOnTint;

  /// Avelã base -- usado no check do símbolo da marca (`--color-accent-2`).
  final Color accent2;

  /// Cor base das sombras (`--shadow-*`).
  final Color shadow;

  static const light = DiaKitColors(
    bg: Color(0xFFF3F2F2),
    surface: Color(0xFFEAE9E9),
    text: Color(0xFF201F1D),
    divider: Color(0x29201F1D),
    neutral500: Color(0xFF9B9797),
    neutral700: Color(0xFF605D5D),
    accent: Color(0xFF8C4A48),
    accentTint: Color(0xFFF7ECE9),
    accentStrong: Color(0xFF582F2D),
    accentOnTint: Color(0xFF3F2221),
    accent2: Color(0xFFA9784F),
    shadow: Color(0xFF2D2B2B),
  );

  static const dark = DiaKitColors(
    bg: Color(0xFF3A2220),
    surface: Color(0xFF4A2B28),
    text: Color(0xFFF3F2F2),
    divider: Color(0x2EF3F2F2),
    neutral500: Color(0xFF9C9690),
    neutral700: Color(0xFFC9C4BE),
    accent: Color(0xFFC17F72),
    accentTint: Color(0xFF3F2221),
    accentStrong: Color(0xFFEED3CE),
    accentOnTint: Color(0xFFEED3CE),
    accent2: Color(0xFFC39C68),
    shadow: Color(0xFF120A09),
  );

  /// `--shadow-sm`: elevação do card em destaque e do card de ilustração.
  List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: shadow.withValues(alpha: 0.14),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// `--shadow-lg`: superfícies flutuantes (dialogs).
  List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: shadow.withValues(alpha: 0.22),
      offset: const Offset(0, 12),
      blurRadius: 32,
    ),
  ];

  @override
  DiaKitColors copyWith({
    Color? bg,
    Color? surface,
    Color? text,
    Color? divider,
    Color? neutral500,
    Color? neutral700,
    Color? accent,
    Color? accentTint,
    Color? accentStrong,
    Color? accentOnTint,
    Color? accent2,
    Color? shadow,
  }) {
    return DiaKitColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      divider: divider ?? this.divider,
      neutral500: neutral500 ?? this.neutral500,
      neutral700: neutral700 ?? this.neutral700,
      accent: accent ?? this.accent,
      accentTint: accentTint ?? this.accentTint,
      accentStrong: accentStrong ?? this.accentStrong,
      accentOnTint: accentOnTint ?? this.accentOnTint,
      accent2: accent2 ?? this.accent2,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  DiaKitColors lerp(covariant DiaKitColors? other, double t) {
    if (other == null) return this;
    return DiaKitColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      neutral500: Color.lerp(neutral500, other.neutral500, t)!,
      neutral700: Color.lerp(neutral700, other.neutral700, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentTint: Color.lerp(accentTint, other.accentTint, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      accentOnTint: Color.lerp(accentOnTint, other.accentOnTint, t)!,
      accent2: Color.lerp(accent2, other.accent2, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension DiaKitColorsX on BuildContext {
  /// Atalho para os tokens de cor da tela atual.
  DiaKitColors get c => Theme.of(this).extension<DiaKitColors>()!;
}

/// Escala de raio do sistema (`--radius-*`).
///
/// O handoff cita "cards com ~20px"; nos arquivos de design esses 20px são o
/// arredondamento da moldura do aparelho, que no app real vem do SO. Os cards de
/// conteúdo usam `--radius-lg` (7px) e os controles usam `--radius-md` (4px).
abstract final class AppRadius {
  static const sm = Radius.circular(2);
  static const md = Radius.circular(4);
  static const lg = Radius.circular(7);

  static const smAll = BorderRadius.all(sm);
  static const mdAll = BorderRadius.all(md);
  static const lgAll = BorderRadius.all(lg);

  /// `.tag` usa `calc(var(--radius-md) * 0.75)`.
  static const tagAll = BorderRadius.all(Radius.circular(3));
}

/// Escala de espaçamento do sistema (`--space-*`, múltiplos de 4.6px).
abstract final class AppSpace {
  static const s1 = 4.6;
  static const s2 = 9.2;
  static const s3 = 13.8;
  static const s4 = 18.4;
  static const s6 = 27.6;
  static const s8 = 36.8;
}

/// Estilos de texto do handoff. Josefin Sans em toda a interface; títulos em
/// semibold (600) -- bold nunca é usado em heading.
abstract final class AppText {
  static const _family = 'JosefinSans';

  /// Wordmark da Splash.
  static const display = TextStyle(
    fontFamily: _family,
    fontSize: 44,
    fontWeight: FontWeight.w600,
    height: 1.12,
    letterSpacing: -0.44,
  );

  /// Título de tela no layout desktop.
  static const h1Desktop = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.12,
    letterSpacing: -0.42,
  );

  /// Saudação da Home.
  static const h1 = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.12,
    letterSpacing: -0.39,
  );

  /// Título de Histórico e Perfil.
  static const h2 = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.12,
    letterSpacing: -0.36,
  );

  /// Título do estado de sucesso.
  static const h3 = TextStyle(
    fontFamily: _family,
    fontSize: 21,
    fontWeight: FontWeight.w600,
    height: 1.12,
    letterSpacing: -0.32,
  );

  /// Título de tela com botão voltar (Converter, Resultado).
  static const h4 = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.12,
    letterSpacing: -0.3,
  );

  /// Título do card em destaque.
  static const h5 = TextStyle(
    fontFamily: _family,
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.29,
  );

  /// Nome do usuário no Perfil.
  static const h6 = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Título dos cards "Em breve".
  static const cardTitle = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Parágrafo da Splash.
  static const bodyLg = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );

  /// Descrição dos cards.
  static const bodySm = TextStyle(
    fontFamily: _family,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Nome de arquivo em cards e linhas do histórico.
  static const bodySmStrong = TextStyle(
    fontFamily: _family,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Nota de privacidade e versão do app.
  static const caption = TextStyle(
    fontFamily: _family,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  /// Tamanho do arquivo.
  static const meta = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Metadados da linha do histórico (hora + tamanho).
  static const metaSm = TextStyle(
    fontFamily: _family,
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// `.kicker` -- rótulo de seção em caixa alta.
  static const kicker = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.88,
  );

  /// `.tag`
  static const tag = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.22,
  );

  /// Rótulo do item da tab bar.
  static const navLabel = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );

  /// `.btn` -- botões usam a familia de heading em semibold.
  static const button = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const buttonSm = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}
