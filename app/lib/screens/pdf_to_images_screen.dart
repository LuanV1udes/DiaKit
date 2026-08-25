import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../l10n/generated/app_localizations.dart';
import '../models/conversion_entry.dart';
import '../services/history_store.dart';
import '../services/pdf_rasterizer.dart';
import '../theme/layout.dart';
import '../theme/tokens.dart';
import '../utils/formatting.dart';
import '../widgets/app_button.dart';
import '../widgets/dashed_box.dart';
import '../widgets/primitives.dart';
import '../widgets/rows.dart';
import '../widgets/screen_header.dart';
import 'images_result_screen.dart';

enum _Status { idle, selected, converting, error }

/// Fluxo de PDF → Imagem: mesmo desenho da tela de Converter, mas
/// rasterizando localmente com [PdfRasterizer] em vez de falar com o
/// backend -- não depende do LibreOffice nem de rede.
class PdfToImagesScreen extends StatefulWidget {
  const PdfToImagesScreen({super.key});

  @override
  State<PdfToImagesScreen> createState() => _PdfToImagesScreenState();
}

class _PdfToImagesScreenState extends State<PdfToImagesScreen> {
  final _rasterizer = const PdfRasterizer();

  XFile? _file;
  String? _fileName;
  int? _fileSize;
  _Status _status = _Status.idle;
  String? _error;
  int _pagesDone = 0;
  int _pagesTotal = 0;

  bool get _supportsDrop =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  bool _draggingOver = false;

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      dialogTitle: l10n.pickPdfDialogTitle,
    );
    if (picked == null) return;
    await _accept(picked.xFile);
  }

  Future<void> _accept(XFile file) async {
    final l10n = AppLocalizations.of(context)!;
    // file.name pode vir com o caminho inteiro em vez de só o nome -- o
    // cross_file so separa pelo separador nativo da plataforma (`\` no
    // Windows), entao um path com `/` (o drop, por exemplo, pode entregar
    // assim) passa direto. p.basename entende os dois.
    final name = p.basename(file.name);
    if (!name.toLowerCase().endsWith('.pdf')) {
      setState(() {
        _status = _Status.error;
        _error = l10n.errorUnsupportedFile('PDF');
      });
      return;
    }

    final size = await file.length();
    if (size > kMaxUploadBytes) {
      setState(() {
        _status = _Status.error;
        _error = l10n.errorFileTooBig(
          formatBytes(size, locale: intlLocale(Localizations.localeOf(context))),
        );
      });
      return;
    }

    setState(() {
      _file = file;
      _fileName = name;
      _fileSize = size;
      _status = _Status.selected;
      _error = null;
    });
  }

  void _remove() {
    setState(() {
      _file = null;
      _fileName = null;
      _fileSize = null;
      _status = _Status.idle;
      _error = null;
    });
  }

  Future<void> _convert() async {
    final file = _file;
    if (file == null) return;

    setState(() {
      _status = _Status.converting;
      _error = null;
      _pagesDone = 0;
      _pagesTotal = 0;
    });

    try {
      final output = await _rasterizer.convertToImages(
        file: file,
        onProgress: (done, total) {
          if (!mounted) return;
          setState(() {
            _pagesDone = done;
            _pagesTotal = total;
          });
        },
      );

      await HistoryStore.instance.add(
        ConversionEntry(
          fileName: _fileName ?? file.name,
          at: DateTime.now(),
          status: ConversionStatus.success,
          kind: ConversionKind.pdfToImages,
          outputPath: output.folder.path,
          sizeBytes: output.totalBytes,
          pageCount: output.pageCount,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ImagesResultScreen(output: output)),
      );
    } on RasterizeException catch (e) {
      if (!mounted) return;
      final message = e.describe(AppLocalizations.of(context)!);

      await HistoryStore.instance.add(
        ConversionEntry(
          fileName: _fileName ?? file.name,
          at: DateTime.now(),
          status: ConversionStatus.error,
          kind: ConversionKind.pdfToImages,
          errorMessage: message,
        ),
      );

      if (!mounted) return;
      setState(() {
        _status = _Status.error;
        _error = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final canConvert = _file != null && _status != _Status.converting;

    final body = Material(
      color: context.c.bg,
      child: isDesktop ? _desktopBody(canConvert) : _mobileBody(canConvert),
    );

    if (!_supportsDrop) return body;

    return DropTarget(
      onDragEntered: (_) => setState(() => _draggingOver = true),
      onDragExited: (_) => setState(() => _draggingOver = false),
      onDragDone: (details) async {
        setState(() => _draggingOver = false);
        if (details.files.isNotEmpty) await _accept(details.files.first);
      },
      child: body,
    );
  }

  Widget _mobileBody(bool canConvert) {
    return Column(
      children: [
        ScreenHeader(
          title: AppLocalizations.of(context)!.pdfToImageTitle,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(24, ScreenHeader.gapAfter(24), 24, 20),
            children: [
              _dropzone(isDesktop: false),
              const SizedBox(height: 20),
              ..._selectedFileSection(isDesktop: false),
              ..._errorSection(),
              const Hairline(),
              const SizedBox(height: 20),
              _privacyNote(),
            ],
          ),
        ),
        _mobileFooter(canConvert),
      ],
    );
  }

  Widget _desktopBody(bool canConvert) {
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(48, 40, 48, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.pdfToImageTitle, style: AppText.h1.copyWith(color: c.text)),
              const SizedBox(height: 28),
              _dropzone(isDesktop: true),
              const SizedBox(height: 24),
              ..._selectedFileSection(isDesktop: true),
              ..._errorSection(),
              if (_status == _Status.converting) ...[
                _progressSection(),
                const SizedBox(height: 16),
              ],
              AppButton(
                label: _buttonLabel(l10n),
                onPressed: canConvert ? _convert : null,
                height: 46,
                horizontalPadding: 28,
              ),
              const SizedBox(height: 24),
              _privacyNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropzone({required bool isDesktop}) {
    final c = context.c;
    final l10n = AppLocalizations.of(context)!;

    return DashedBox(
      onTap: _status == _Status.converting ? null : _pick,
      highlighted: _draggingOver,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isDesktop ? 56 : 36,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.cloudUpload, size: isDesktop ? 36 : 32, color: c.accent),
          SizedBox(height: isDesktop ? 14 : 12),
          Text(
            _supportsDrop && isDesktop
                ? l10n.dropzoneDragPdf
                : l10n.dropzoneTapPdf,
            textAlign: TextAlign.center,
            style: AppText.h6.copyWith(
              fontSize: isDesktop ? 16 : 15,
              color: c.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.uploadHint('PDF'),
            style: (isDesktop ? AppText.bodySm : AppText.caption).copyWith(
              fontSize: isDesktop ? 13 : 12.5,
              color: c.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _selectedFileSection({required bool isDesktop}) {
    final file = _file;
    if (file == null) return const [];
    final l10n = AppLocalizations.of(context)!;

    return [
      Kicker(l10n.selectedFileKicker, bottom: 10),
      FileCard(
        icon: LucideIcons.fileText,
        name: _fileName ?? file.name,
        meta: formatBytes(_fileSize, locale: intlLocale(Localizations.localeOf(context))),
        onRemove: _status == _Status.converting ? null : _remove,
        padding: EdgeInsets.all(isDesktop ? 16 : 14),
      ),
      SizedBox(height: isDesktop ? 32 : 28),
    ];
  }

  List<Widget> _errorSection() {
    final error = _error;
    if (error == null) return const [];
    final c = context.c;

    return [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: c.accent),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.fileX, size: 20, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(error, style: AppText.bodySm.copyWith(color: c.text)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  Widget _privacyNote() {
    final c = context.c;
    return Text(
      AppLocalizations.of(context)!.privacyNoteLocalImages,
      style: AppText.caption.copyWith(color: c.neutral500),
    );
  }

  String _buttonLabel(AppLocalizations l10n) => switch (_status) {
    _Status.converting when _pagesTotal > 0 =>
      l10n.pageProgress(_pagesDone, _pagesTotal),
    _Status.converting => l10n.convertingLabel,
    _ => l10n.convertToImageButton,
  };

  Widget _progressSection() {
    final progress = _pagesTotal > 0 ? _pagesDone / _pagesTotal : null;
    return SizedBox(
      height: 2,
      child: LinearProgressIndicator(minHeight: 2, value: progress),
    );
  }

  Widget _mobileFooter(bool canConvert) {
    final c = context.c;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_status == _Status.converting) _progressSection(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: SafeArea(
              top: false,
              child: AppButton(
                label: _buttonLabel(AppLocalizations.of(context)!),
                onPressed: canConvert ? _convert : null,
                expand: true,
                height: 48,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
