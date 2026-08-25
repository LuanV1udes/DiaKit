import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../l10n/generated/app_localizations.dart';
import '../models/conversion_entry.dart';
import '../services/converter_client.dart';
import '../services/history_store.dart';
import '../services/settings_store.dart';
import '../theme/layout.dart';
import '../theme/tokens.dart';
import '../utils/formatting.dart';
import '../widgets/app_button.dart';
import '../widgets/dashed_box.dart';
import '../widgets/primitives.dart';
import '../widgets/rows.dart';
import '../widgets/screen_header.dart';
import 'result_screen.dart';

enum _Status { idle, selected, converting, error }

/// Extensões aceitas e para qual formato cada uma converte -- a direção é
/// deduzida do arquivo escolhido, não escolhida pelo usuário: um .csv vira
/// planilha, uma planilha vira .csv.
const _targetByExtension = {
  'csv': 'xlsx',
  'xls': 'csv',
  'xlsx': 'csv',
};

/// Fluxo CSV ↔ Excel: mesmo desenho das outras telas de conversão, mas a
/// direção (para XLSX ou para CSV) depende do arquivo escolhido em vez de
/// ser fixa.
class CsvExcelScreen extends StatefulWidget {
  const CsvExcelScreen({super.key});

  @override
  State<CsvExcelScreen> createState() => _CsvExcelScreenState();
}

class _CsvExcelScreenState extends State<CsvExcelScreen> {
  final _settings = SettingsStore();
  final _converter = const ConverterClient();

  XFile? _file;
  String? _fileName;
  int? _fileSize;
  String? _targetFormat;
  _Status _status = _Status.idle;
  String? _error;
  String _serverUrl = SettingsStore.defaultServerUrl;

  bool get _supportsDrop =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  bool _draggingOver = false;

  @override
  void initState() {
    super.initState();
    _settings.serverUrl().then((url) {
      if (mounted) setState(() => _serverUrl = url);
    });
  }

  Future<void> _pick() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: _targetByExtension.keys.toList(),
      dialogTitle: l10n.pickCsvDialogTitle,
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
    final extension = p.extension(name).replaceFirst('.', '').toLowerCase();
    final target = _targetByExtension[extension];

    if (target == null) {
      setState(() {
        _status = _Status.error;
        _error = l10n.errorUnsupportedFile(l10n.csvTypesLabel);
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
      _targetFormat = target;
      _status = _Status.selected;
      _error = null;
    });
  }

  void _remove() {
    setState(() {
      _file = null;
      _fileName = null;
      _fileSize = null;
      _targetFormat = null;
      _status = _Status.idle;
      _error = null;
    });
  }

  Future<void> _convert() async {
    final file = _file;
    final target = _targetFormat;
    if (file == null || target == null) return;

    setState(() {
      _status = _Status.converting;
      _error = null;
    });

    try {
      final output = await _converter.convertToFormat(
        file: file,
        serverUrl: _serverUrl,
        targetFormat: target,
      );

      await HistoryStore.instance.add(
        ConversionEntry(
          fileName: output.name,
          at: DateTime.now(),
          status: ConversionStatus.success,
          outputPath: output.file.path,
          sizeBytes: output.sizeBytes,
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            output: output,
            kind: target == 'xlsx' ? ResultFileKind.xlsx : ResultFileKind.csv,
            onConvertAnother: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CsvExcelScreen()),
            ),
          ),
        ),
      );
    } on ConverterException catch (e) {
      if (!mounted) return;
      final message = e.describe(AppLocalizations.of(context)!);

      await HistoryStore.instance.add(
        ConversionEntry(
          fileName: _fileName ?? file.name,
          at: DateTime.now(),
          status: ConversionStatus.error,
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

  String _buttonLabel(AppLocalizations l10n) {
    if (_status == _Status.converting) return l10n.convertingLabel;
    return switch (_targetFormat) {
      'xlsx' => l10n.convertToExcelButton,
      'csv' => l10n.convertToCsvButton,
      _ => l10n.convertGenericButton,
    };
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
          title: AppLocalizations.of(context)!.toolCsvExcel,
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
              Text(l10n.toolCsvExcel, style: AppText.h1.copyWith(color: c.text)),
              const SizedBox(height: 28),
              _dropzone(isDesktop: true),
              const SizedBox(height: 24),
              ..._selectedFileSection(isDesktop: true),
              ..._errorSection(),
              if (_status == _Status.converting) ...[
                _progressBar(),
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
                ? l10n.dropzoneDragCsv
                : l10n.dropzoneTapCsv,
            textAlign: TextAlign.center,
            style: AppText.h6.copyWith(
              fontSize: isDesktop ? 16 : 15,
              color: c.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.uploadHint(l10n.csvTypesLabel),
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
    final c = context.c;
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
      const SizedBox(height: 10),
      Text(
        _targetFormat == 'xlsx' ? l10n.willBecomeXlsx : l10n.willBecomeCsv,
        style: AppText.caption.copyWith(color: c.neutral500),
      ),
      SizedBox(height: isDesktop ? 28 : 24),
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
    final origin = Uri.tryParse(_serverUrl)?.origin ?? _serverUrl;

    return Text(
      AppLocalizations.of(context)!.privacyNoteServerConversion(origin),
      style: AppText.caption.copyWith(color: c.neutral500),
    );
  }

  Widget _progressBar() {
    return const SizedBox(
      height: 2,
      child: LinearProgressIndicator(minHeight: 2),
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
          if (_status == _Status.converting) _progressBar(),
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
