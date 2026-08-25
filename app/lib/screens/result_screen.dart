import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/converter_client.dart';
import '../theme/layout.dart';
import '../theme/tokens.dart';
import '../utils/formatting.dart';
import '../widgets/app_button.dart';
import '../widgets/rows.dart';
import '../widgets/screen_header.dart';
import '../widgets/success_badge.dart';
import 'convert_screen.dart';

/// Tipo do arquivo de saída -- muda rótulos, mimetype e extensão do diálogo
/// de salvar, mas não a estrutura da tela. [ResultScreen] usa
/// [ResultFileKind.pdf] por padrão porque foi o primeiro conversor do app;
/// CSV ↔ Excel usa [xlsx]/[csv]. Os rótulos variam com o idioma, então vêm de
/// métodos (que pedem um [AppLocalizations]) em vez de campos `const`.
enum ResultFileKind {
  pdf(mimeType: 'application/pdf', extensions: ['pdf']),
  xlsx(
    mimeType:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    extensions: ['xlsx'],
  ),
  csv(mimeType: 'text/csv', extensions: ['csv']);

  const ResultFileKind({required this.mimeType, required this.extensions});

  final String mimeType;
  final List<String> extensions;

  String downloadLabel(AppLocalizations l10n) => switch (this) {
    ResultFileKind.pdf => l10n.downloadPdfButton,
    ResultFileKind.xlsx => l10n.downloadExcelButton,
    ResultFileKind.csv => l10n.downloadCsvButton,
  };

  String savedMessage(AppLocalizations l10n) => switch (this) {
    ResultFileKind.pdf => l10n.savedPdfMessage,
    ResultFileKind.xlsx => l10n.savedSpreadsheetMessage,
    ResultFileKind.csv => l10n.savedCsvMessage,
  };

  String saveDialogTitle(AppLocalizations l10n) => switch (this) {
    ResultFileKind.pdf => l10n.savePdfDialogTitle,
    ResultFileKind.xlsx => l10n.saveSpreadsheetDialogTitle,
    ResultFileKind.csv => l10n.saveCsvDialogTitle,
  };

  String subtitle(AppLocalizations l10n) => switch (this) {
    ResultFileKind.pdf => l10n.subtitlePdf,
    ResultFileKind.xlsx => l10n.subtitleSpreadsheet,
    ResultFileKind.csv => l10n.subtitleCsv,
  };
}

/// Telas 04 (mobile) e 15 (desktop) — Conversão concluída.
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.output,
    this.kind = ResultFileKind.pdf,
    this.onConvertAnother,
    this.convertAnotherLabel,
  });

  final ConversionOutput output;
  final ResultFileKind kind;

  /// Sem isso, volta para a tela de Converter (o único fluxo até o CSV ↔
  /// Excel existir). Outros fluxos passam a própria tela de origem aqui.
  final VoidCallback? onConvertAnother;

  /// `null` usa [AppLocalizations.convertAnotherFileButton] -- não dá para
  /// resolver isso num valor `const` do construtor, que não tem `context`.
  final String? convertAnotherLabel;

  Future<void> _download(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    try {
      final bytes = await output.file.readAsBytes();
      final saved = await FilePicker.saveFile(
        fileName: output.name,
        bytes: bytes,
        mimeType: kind.mimeType,
        type: FileType.custom,
        allowedExtensions: kind.extensions,
        dialogTitle: kind.saveDialogTitle(l10n),
      );
      if (saved == null) return; // usuário cancelou o diálogo

      messenger.showSnackBar(SnackBar(content: Text(kind.savedMessage(l10n))));
    } catch (_) {
      // Sem diálogo de salvar disponível: abre o arquivo para o usuário
      // decidir o que fazer com ele.
      final result = await OpenFilex.open(output.file.path);
      if (result.type != ResultType.done) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.errorCouldNotSave(result.message))),
        );
      }
    }
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(output.file.path, mimeType: kind.mimeType)],
        fileNameOverrides: [output.name],
      ),
    );
  }

  void _convertAnother(BuildContext context) {
    if (onConvertAnother != null) {
      onConvertAnother!();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ConvertScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Empilhada dentro do Navigator da aba Início: precisa da própria
    // superfície opaca.
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
                            l10n.fileReadyTitle,
                            style: AppText.h3.copyWith(color: c.text),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            kind.subtitle(l10n),
                            style: AppText.bodySm.copyWith(color: c.neutral700),
                          ),
                          const SizedBox(height: 28),
                          FileCard(
                            icon: LucideIcons.fileCheck2,
                            name: output.name,
                            meta: formatBytes(
                              output.sizeBytes,
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
                  label: kind.downloadLabel(l10n),
                  icon: LucideIcons.download,
                  onPressed: () => _download(context),
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
                    label: convertAnotherLabel ?? l10n.convertAnotherFileButton,
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
              l10n.fileReadyTitle,
              style: AppText.h2.copyWith(color: c.text),
            ),
            const SizedBox(height: 8),
            Text(
              kind.subtitle(l10n),
              style: AppText.body.copyWith(color: c.neutral700),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 360,
              child: FileCard(
                icon: LucideIcons.fileCheck2,
                name: output.name,
                meta: formatBytes(
                  output.sizeBytes,
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
                  label: kind.downloadLabel(l10n),
                  icon: LucideIcons.download,
                  onPressed: () => _download(context),
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
