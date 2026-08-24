import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';

import '../models/conversion_entry.dart';
import '../services/history_store.dart';
import '../theme/layout.dart';
import '../theme/tokens.dart';
import '../utils/formatting.dart';
import '../widgets/primitives.dart';

/// Telas 05 (mobile) e 16 (desktop) — Histórico.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isDesktop = context.isDesktop;

    return ListenableBuilder(
      listenable: HistoryStore.instance,
      builder: (context, _) {
        final groups = _groupByDay(HistoryStore.instance.entries);

        return ListView(
          padding: isDesktop
              ? const EdgeInsets.fromLTRB(48, 40, 48, 40)
              : const EdgeInsets.fromLTRB(24, 24, 24, 12),
          children: [
            Text(
              'Histórico',
              style: (isDesktop ? AppText.h1Desktop : AppText.h2).copyWith(
                color: c.text,
              ),
            ),
            SizedBox(height: isDesktop ? 32 : 24),
            if (groups.isEmpty)
              const _EmptyState()
            else
              for (final group in groups) ...[
                Kicker(group.label, bottom: isDesktop ? 12 : 10),
                ContentWidth(
                  maxWidth: isDesktop ? 760 : double.infinity,
                  child: Column(
                    children: [
                      for (var i = 0; i < group.entries.length; i++)
                        _HistoryRow(
                          entry: group.entries[i],
                          isDesktop: isDesktop,
                          divided: i < group.entries.length - 1,
                        ),
                    ],
                  ),
                ),
                SizedBox(height: isDesktop ? 28 : 24),
              ],
          ],
        );
      },
    );
  }
}

/// Um bloco de linhas com o mesmo rótulo de data ("Hoje", "Ontem", ...).
class _DayGroup {
  _DayGroup(this.label) : entries = [];

  final String label;
  final List<ConversionEntry> entries;
}

List<_DayGroup> _groupByDay(List<ConversionEntry> entries) {
  final groups = <_DayGroup>[];

  for (final entry in entries) {
    final label = dayLabel(entry.at);
    if (groups.isEmpty || groups.last.label != label) {
      groups.add(_DayGroup(label));
    }
    groups.last.entries.add(entry);
  }

  return groups;
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.isDesktop,
    required this.divided,
  });

  final ConversionEntry entry;
  final bool isDesktop;

  /// A última linha do grupo não leva hairline.
  final bool divided;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    if (entry.status == ConversionStatus.error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(entry.errorMessage ?? 'A conversão falhou.'),
        ),
      );
      return;
    }

    final path = entry.outputPath;
    final missingMessage = entry.kind == ConversionKind.pdfToImages
        ? 'Essas imagens não estão mais no aparelho.'
        : 'Esse PDF não está mais no aparelho.';
    if (path == null ||
        !(entry.kind == ConversionKind.pdfToImages
            ? Directory(path).existsSync()
            : File(path).existsSync())) {
      messenger.showSnackBar(SnackBar(content: Text(missingMessage)));
      return;
    }

    await OpenFilex.open(path);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final failed = entry.status == ConversionStatus.error;
    final isImages = entry.kind == ConversionKind.pdfToImages;

    final successMeta = isImages
        ? '${entry.pageCount ?? 0} ${entry.pageCount == 1 ? 'imagem' : 'imagens'}'
        : formatBytes(entry.sizeBytes);
    final meta = failed
        ? '${formatTime(entry.at)} · falhou'
        : '${formatTime(entry.at)} · $successMeta';

    return DecoratedBox(
      decoration: BoxDecoration(
        border: divided
            ? Border(bottom: BorderSide(color: c.divider))
            : const Border(),
      ),
      child: InkWell(
        onTap: () => _open(context),
        hoverColor: c.text.withValues(alpha: 0.04),
        splashColor: c.text.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isDesktop ? 14 : 12),
          child: Row(
            children: [
              Icon(
                failed
                    ? LucideIcons.fileX
                    : (isImages ? LucideIcons.image : LucideIcons.fileCheck2),
                size: 20,
                color: failed ? c.neutral500 : c.accentStrong,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodySmStrong.copyWith(
                        fontSize: isDesktop ? 14 : 13.5,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: (isDesktop ? AppText.meta : AppText.metaSm)
                          .copyWith(color: c.neutral500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppTag(
                failed ? 'Erro' : 'Concluído',
                variant: failed ? AppTagVariant.outline : AppTagVariant.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O handoff não desenha o histórico vazio; seguimos o mesmo tom das legendas.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(LucideIcons.history, size: 32, color: c.neutral500),
          const SizedBox(height: 14),
          Text(
            'Nenhuma conversão por aqui ainda.',
            style: AppText.bodySmStrong.copyWith(color: c.text),
          ),
          const SizedBox(height: 4),
          Text(
            'Os arquivos que você converter aparecem nesta lista.',
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: c.neutral500),
          ),
        ],
      ),
    );
  }
}
