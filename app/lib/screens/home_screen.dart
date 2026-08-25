import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/layout.dart';
import '../theme/tokens.dart';
import '../widgets/app_button.dart';
import '../widgets/primitives.dart';

/// Telas 02 (mobile) e 13 (desktop) — Home.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenConverter,
    required this.onOpenPdfToImages,
    required this.onOpenCsvExcel,
    required this.onOpenProfile,
  });

  final VoidCallback onOpenConverter;
  final VoidCallback onOpenPdfToImages;
  final VoidCallback onOpenCsvExcel;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = context.isDesktop;

    return ListView(
      padding: isDesktop
          ? const EdgeInsets.fromLTRB(48, 40, 48, 40)
          : const EdgeInsets.fromLTRB(24, 24, 24, 12),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Kicker(l10n.homeGreeting),
                  SizedBox(height: isDesktop ? 4 : 2),
                  Text(
                    l10n.homeQuestion,
                    style: (isDesktop ? AppText.h1Desktop : AppText.h1)
                        .copyWith(color: c.text),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s3),
            AppIconButton(
              icon: LucideIcons.user,
              onPressed: onOpenProfile,
              tooltip: l10n.navProfile,
            ),
          ],
        ),
        SizedBox(height: isDesktop ? 36 : 28),
        ContentWidth(
          maxWidth: isDesktop ? 420 : double.infinity,
          child: _ConverterCard(onTap: onOpenConverter, isDesktop: isDesktop),
        ),
        SizedBox(height: isDesktop ? 40 : 32),
        Kicker(l10n.homeToolsKicker, bottom: isDesktop ? 16 : 14),
        ContentWidth(
          maxWidth: isDesktop ? 900 : double.infinity,
          child: _UpcomingGrid(
            tools: [
              _Tool(LucideIcons.image, l10n.toolPdfToImage, onTap: onOpenPdfToImages),
              _Tool(LucideIcons.fileSpreadsheet, l10n.toolCsvExcel, onTap: onOpenCsvExcel),
              _Tool(LucideIcons.fileSymlink, l10n.toolPdfToWord),
              _Tool(LucideIcons.minimize2, l10n.toolCompressPdf),
              _Tool(LucideIcons.signature, l10n.toolSignPdf),
            ],
            columns: isDesktop ? 4 : 2,
            gap: isDesktop ? 16 : 14,
            padding: isDesktop ? 18 : 16,
          ),
        ),
      ],
    );
  }
}

/// Card em destaque da ferramenta ativa: contorno accent em vez do hairline.
class _ConverterCard extends StatelessWidget {
  const _ConverterCard({required this.onTap, required this.isDesktop});

  final VoidCallback onTap;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;
    final chip = isDesktop ? 48.0 : 44.0;

    return OutlinedCard(
      onTap: onTap,
      elevated: true,
      borderColor: c.accent,
      padding: EdgeInsets.all(isDesktop ? 28 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: chip,
                height: chip,
                decoration: BoxDecoration(
                  color: c.accentTint,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(
                  LucideIcons.fileOutput,
                  size: isDesktop ? 24 : 22,
                  color: c.accentStrong,
                ),
              ),
              const Spacer(),
              Icon(LucideIcons.arrowRight, size: 18, color: c.accent),
            ],
          ),
          SizedBox(height: isDesktop ? 16 : 14),
          Text(
            l10n.convertToPdfTitle,
            style: AppText.h5.copyWith(
              fontSize: isDesktop ? 20 : 19,
              color: c.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.convertToPdfDescription,
            style: (isDesktop ? AppText.body : AppText.bodySm).copyWith(
              color: c.neutral700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma ferramenta da grade abaixo do card em destaque. [onTap] nulo é o
/// estado bloqueado do mockup original; presente, vira um card normal.
class _Tool {
  const _Tool(this.icon, this.label, {this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

/// Grade de ferramentas. As bloqueadas ficam a 55% de opacidade com um
/// cadeado no canto, como no mockup original; as liberadas são cards normais
/// com o ícone destacado no tint do accent, no mesmo padrão do card do
/// conversor.
class _UpcomingGrid extends StatelessWidget {
  const _UpcomingGrid({
    required this.tools,
    required this.columns,
    required this.gap,
    required this.padding,
  });

  final List<_Tool> tools;
  final int columns;
  final double gap;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tool in tools)
              SizedBox(
                width: width,
                child: tool.onTap == null
                    ? _LockedTile(tool: tool, padding: padding)
                    : _UnlockedTile(tool: tool, padding: padding),
              ),
          ],
        );
      },
    );
  }
}

class _LockedTile extends StatelessWidget {
  const _LockedTile({required this.tool, required this.padding});

  final _Tool tool;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Opacity(
      opacity: 0.55,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: c.divider),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tool.icon, size: 24, color: c.neutral700),
                const SizedBox(height: 10),
                Text(
                  tool.label,
                  style: AppText.cardTitle.copyWith(color: c.text),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Icon(LucideIcons.lock, size: 14, color: c.neutral500),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockedTile extends StatelessWidget {
  const _UnlockedTile({required this.tool, required this.padding});

  final _Tool tool;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return OutlinedCard(
      onTap: tool.onTap,
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.accentTint,
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(tool.icon, size: 17, color: c.accentStrong),
          ),
          const SizedBox(height: 10),
          Text(
            tool.label,
            style: AppText.cardTitle.copyWith(color: c.text),
          ),
        ],
      ),
    );
  }
}
