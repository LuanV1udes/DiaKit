import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tokens.dart';

/// Card de arquivo: ícone, nome, tamanho e uma ação opcional à direita.
/// Aparece na tela de conversão (com o "x" de remover) e no resultado.
class FileCard extends StatelessWidget {
  const FileCard({
    super.key,
    required this.icon,
    required this.name,
    required this.meta,
    this.onRemove,
    this.padding = const EdgeInsets.all(14),
    this.iconSize = 26,
  });

  final IconData icon;
  final String name;
  final String meta;
  final VoidCallback? onRemove;
  final EdgeInsetsGeometry padding;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: c.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: iconSize, color: c.accentStrong),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodySmStrong.copyWith(color: c.text),
                ),
                const SizedBox(height: 2),
                Text(meta, style: AppText.meta.copyWith(color: c.neutral500)),
              ],
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: onRemove,
              icon: Icon(LucideIcons.x, size: 16, color: c.neutral500),
              tooltip: 'Remover arquivo',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

/// Linha de um grupo de configurações do Perfil: ícone, rótulo, valor opcional
/// e chevron. As linhas de um grupo são separadas por hairline.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.dense = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  /// `true` usa o padding do mockup mobile (14×16); `false`, o do desktop (16×18).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return InkWell(
      onTap: onTap,
      hoverColor: c.text.withValues(alpha: 0.04),
      splashColor: c.text.withValues(alpha: 0.06),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: dense
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
            : const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c.text),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppText.body.copyWith(color: c.text)),
            ),
            if (value != null) ...[
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppText.bodySm.copyWith(
                    fontSize: 13,
                    color: c.neutral500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(LucideIcons.chevronRight, size: 16, color: c.neutral500),
          ],
        ),
      ),
    );
  }
}

/// Agrupa [SettingsRow]s num card com hairline entre as linhas.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: c.divider),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Container(height: 1, color: c.divider),
            rows[i],
          ],
        ],
      ),
    );
  }
}
