import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tokens.dart';

/// Círculo com check que marca o sucesso de uma conversão -- usado nas telas
/// de resultado do conversor de documentos e do PDF → Imagem.
class SuccessBadge extends StatelessWidget {
  const SuccessBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.accent, width: 1.5),
      ),
      child: Icon(LucideIcons.check, size: 36, color: c.accentStrong),
    );
  }
}
