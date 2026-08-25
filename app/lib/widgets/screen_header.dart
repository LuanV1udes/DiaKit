import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';

/// Cabeçalho das telas empilhadas no mobile: seta de voltar + título.
///
/// O mockup posiciona a seta de 20px na margem de 24px da tela, mas o
/// [IconButton] do Material reserva 48px de alvo de toque em volta do ícone.
/// Recuar a linha em [tapInset] devolve o ícone à margem do design sem encolher
/// o alvo de toque, e aí o título encosta logo depois dos 48px do botão -- que é
/// exatamente onde o mockup o coloca.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.horizontalPadding = 24,
    this.top = 20,
  });

  final String title;
  final VoidCallback? onBack;

  /// Margem horizontal do conteúdo da tela.
  final double horizontalPadding;

  /// Distância do topo até o título, como no mockup.
  final double top;

  /// Metade da folga que o alvo de toque de 48px acrescenta ao ícone de 20px.
  static const tapInset = 14.0;

  /// Meia altura da linha do título (20px × 1.12), usada para alinhar o texto
  /// à mesma altura do mockup apesar do botão mais alto.
  static const _titleHalf = 11.2;

  /// Quanto ainda falta de espaço depois do cabeçalho para chegar ao início do
  /// conteúdo, dado o `margin-bottom` do mockup.
  static double gapAfter(double marginBottom) =>
      marginBottom - (24 - _titleHalf);

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding - tapInset,
        top: top - (24 - _titleHalf),
        right: horizontalPadding,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(LucideIcons.arrowLeft, size: 20, color: c.text),
            tooltip: AppLocalizations.of(context)!.backTooltip,
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.h4.copyWith(color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}
