import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/pdf_rasterizer.dart';
import '../theme/layout.dart';
import '../theme/tokens.dart';
import '../utils/formatting.dart';
import '../widgets/app_button.dart';
import '../widgets/rows.dart';
import '../widgets/screen_header.dart';
import '../widgets/success_badge.dart';
import 'pdf_to_images_screen.dart';

/// Tela de resultado do PDF → Imagem. Segue o mesmo desenho da tela 04
/// (Conversão concluída), mas com uma faixa de miniaturas no lugar do
/// `FileCard` único e "Abrir pasta" no lugar de "Baixar PDF" -- não faz
/// sentido baixar N arquivos por um diálogo de salvar de arquivo único.
class ImagesResultScreen extends StatelessWidget {
  const ImagesResultScreen({super.key, required this.output});

  final PdfImagesOutput output;

  Future<void> _openFolder(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final result = await OpenFilex.open(output.folder.path);
    if (result.type != ResultType.done) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorCouldNotOpenFolder(result.message))),
      );
    }
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          for (final image in output.images)
            XFile(image.path, mimeType: 'image/png'),
        ],
      ),
    );
  }

  void _convertAnother(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PdfToImagesScreen()),
    );
  }

  String _summaryLabel(AppLocalizations l10n) => l10n.imageCount(output.pageCount);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.c.bg,
      child: context.isDesktop ? _desktop(context) : _mobile(context),
    );
  }

  Widget _mobile(BuildContext context) {
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(
          title: l10n.conversionDoneTitle,
          onBack: () => Navigator.of(context).maybePop(),
          horizontalPadding: 28,
          top: 32,
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(28, ScreenHeader.gapAfter(32), 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SuccessBadge(),
                          const SizedBox(height: 24),
                          Text(
                            l10n.imagesReadyTitle,
                            style: AppText.h3.copyWith(color: c.text),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.imagesReadySubtitle,
                            style: AppText.bodySm.copyWith(color: c.neutral700),
                          ),
                          const SizedBox(height: 28),
                          _ThumbnailStrip(images: output.images),
                          const SizedBox(height: 16),
                          FileCard(
                            icon: LucideIcons.image,
                            name: _summaryLabel(l10n),
                            meta: formatBytes(
                              output.totalBytes,
                              locale: intlLocale(Localizations.localeOf(context)),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AppButton(
                  label: l10n.openFolderButton,
                  icon: LucideIcons.folderOpen,
                  onPressed: () => _openFolder(context),
                  expand: true,
                  height: 48,
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: l10n.shareButton,
                  icon: LucideIcons.share2,
                  variant: AppButtonVariant.secondary,
                  onPressed: _share,
                  expand: true,
                  height: 44,
                  textStyle: AppText.buttonSm,
                ),
                const SizedBox(height: 4),
                Align(
                  child: AppButton(
                    label: l10n.convertAnotherPdfButton,
                    variant: AppButtonVariant.ghost,
                    onPressed: () => _convertAnother(context),
                    height: 40,
                    textStyle: AppText.buttonSm,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _desktop(BuildContext context) {
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(48, 40, 48, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SuccessBadge(),
            const SizedBox(height: 24),
            Text(
              l10n.imagesReadyTitle,
              style: AppText.h2.copyWith(color: c.text),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.imagesReadySubtitle,
              style: AppText.body.copyWith(color: c.neutral700),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 480,
              child: _ThumbnailStrip(images: output.images),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 360,
              child: FileCard(
                icon: LucideIcons.image,
                name: _summaryLabel(l10n),
                meta: formatBytes(
                  output.totalBytes,
                  locale: intlLocale(Localizations.localeOf(context)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  label: l10n.openFolderButton,
                  icon: LucideIcons.folderOpen,
                  onPressed: () => _openFolder(context),
                  height: 44,
                  horizontalPadding: 24,
                  textStyle: AppText.buttonSm,
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: l10n.shareButton,
                  icon: LucideIcons.share2,
                  variant: AppButtonVariant.secondary,
                  onPressed: _share,
                  height: 44,
                  horizontalPadding: 24,
                  textStyle: AppText.buttonSm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Faixa horizontal com uma miniatura de cada página gerada.
class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({required this.images});

  final List<File> images;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: AppRadius.mdAll,
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: c.divider)),
              child: Image.file(images[index], height: 96, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}
