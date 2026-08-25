import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../l10n/generated/app_localizations.dart';

enum _ConverterErrorKind {
  invalidServerUrl,
  httpError,
  serverMessage,
  timeout,
  unreachable,
  transport,
}

/// Falha de conversão. Carrega só os dados do problema -- quem decide a
/// frase final (e em que idioma) é [describe], chamado pela tela que pegou o
/// `catch`, onde há um [AppLocalizations] disponível.
class ConverterException implements Exception {
  const ConverterException.invalidServerUrl()
    : _kind = _ConverterErrorKind.invalidServerUrl,
      _statusCode = null,
      _seconds = null,
      _text = null;

  const ConverterException.httpError(int statusCode)
    : _kind = _ConverterErrorKind.httpError,
      _statusCode = statusCode,
      _seconds = null,
      _text = null;

  /// Mensagem já pronta em `{ "error": "..." }` na resposta do backend -- não
  /// dá para traduzir um texto que o próprio servidor escolheu.
  const ConverterException.serverMessage(String message)
    : _kind = _ConverterErrorKind.serverMessage,
      _text = message,
      _statusCode = null,
      _seconds = null;

  const ConverterException.timeout(int seconds)
    : _kind = _ConverterErrorKind.timeout,
      _seconds = seconds,
      _statusCode = null,
      _text = null;

  const ConverterException.unreachable(String origin)
    : _kind = _ConverterErrorKind.unreachable,
      _text = origin,
      _statusCode = null,
      _seconds = null;

  const ConverterException.transport(String error)
    : _kind = _ConverterErrorKind.transport,
      _text = error,
      _statusCode = null,
      _seconds = null;

  final _ConverterErrorKind _kind;
  final int? _statusCode;
  final int? _seconds;
  final String? _text;

  String describe(AppLocalizations l10n) => switch (_kind) {
    _ConverterErrorKind.invalidServerUrl => l10n.errorInvalidServerUrl,
    _ConverterErrorKind.httpError => l10n.errorHttpFailure(_statusCode!),
    _ConverterErrorKind.serverMessage => _text!,
    _ConverterErrorKind.timeout => l10n.errorTimeout(_seconds!),
    _ConverterErrorKind.unreachable => l10n.errorUnreachable(_text!),
    _ConverterErrorKind.transport => l10n.errorTransport(_text!),
  };
}

/// Arquivo pronto, gravado no diretório de documentos do app.
class ConversionOutput {
  const ConversionOutput({required this.file, required this.sizeBytes});

  final File file;
  final int sizeBytes;

  String get name => file.uri.pathSegments.last;
}

/// Cliente do serviço de conversão do backend Node em `backend/`, que por sua
/// vez chama o LibreOffice em modo headless. Cobre as duas rotas: `/to-pdf`
/// (sempre PDF) e `/to-format` (formato de saída escolhido pelo chamador,
/// hoje usado por CSV ↔ Excel).
class ConverterClient {
  const ConverterClient();

  /// O backend derruba o LibreOffice em 120s; a primeira conversão depois de
  /// o backend subir é mais lenta (~10s) porque inicializa o perfil do
  /// LibreOffice do zero. A margem aqui cobre isso mais o upload/download.
  static const _timeout = Duration(seconds: 150);

  Future<ConversionOutput> convertToPdf({
    required XFile file,
    required String serverUrl,
  }) {
    return _convert(
      file: file,
      serverUrl: serverUrl,
      endpoint: '/convert/to-pdf',
      outputExtension: 'pdf',
    );
  }

  /// [targetFormat] é o token que o LibreOffice espera em `--convert-to`
  /// (`xlsx`, `csv`, ...) -- vira tanto o campo `target` do form quanto a
  /// extensão do arquivo salvo.
  Future<ConversionOutput> convertToFormat({
    required XFile file,
    required String serverUrl,
    required String targetFormat,
  }) {
    return _convert(
      file: file,
      serverUrl: serverUrl,
      endpoint: '/convert/to-format',
      outputExtension: targetFormat,
      extraFields: {'target': targetFormat},
    );
  }

  Future<ConversionOutput> _convert({
    required XFile file,
    required String serverUrl,
    required String endpoint,
    required String outputExtension,
    Map<String, String> extraFields = const {},
  }) async {
    final uri = Uri.tryParse('${serverUrl.trim()}$endpoint');
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const ConverterException.invalidServerUrl();
    }

    final http.Response response;
    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields.addAll(extraFields)
        ..files.add(
          http.MultipartFile(
            'file',
            file.openRead(),
            await file.length(),
            filename: file.name,
          ),
        );

      response = await http.Response.fromStream(
        await request.send().timeout(_timeout),
      );
    } on Exception catch (e) {
      throw _transportFailure(e, uri);
    }

    if (response.statusCode != 200) {
      throw _serverError(response);
    }

    final outputDir = await getApplicationDocumentsDirectory();
    // file.name pode vir com o caminho inteiro em vez de só o nome -- o
    // cross_file so separa pelo separador nativo da plataforma (`\` no
    // Windows), entao um path com `/` passa direto. p.basename entende os
    // dois.
    final baseName = p.basenameWithoutExtension(file.name);
    final output = File(
      '${outputDir.path}/'
      '${_unique(outputDir, baseName, outputExtension)}.$outputExtension',
    );
    await output.writeAsBytes(response.bodyBytes);

    return ConversionOutput(file: output, sizeBytes: response.bodyBytes.length);
  }

  /// Evita sobrescrever um arquivo anterior de mesmo nome — o Histórico
  /// aponta para os arquivos antigos e eles precisam continuar abrindo.
  String _unique(Directory dir, String baseName, String extension) {
    if (!File('${dir.path}/$baseName.$extension').existsSync()) return baseName;

    var attempt = 2;
    while (File('${dir.path}/$baseName ($attempt).$extension').existsSync()) {
      attempt++;
    }
    return '$baseName ($attempt)';
  }

  ConverterException _serverError(http.Response response) {
    // O backend responde `{ "error": "..." }` nos casos previstos.
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] is String) {
        return ConverterException.serverMessage(body['error'] as String);
      }
    } catch (_) {
      // Resposta que não é JSON: cai no texto genérico abaixo.
    }
    return ConverterException.httpError(response.statusCode);
  }

  ConverterException _transportFailure(Exception e, Uri uri) {
    if (e is TimeoutException) {
      return ConverterException.timeout(_timeout.inSeconds);
    }
    if (e is SocketException || e is http.ClientException) {
      return ConverterException.unreachable(uri.origin);
    }
    return ConverterException.transport(e.toString());
  }
}
