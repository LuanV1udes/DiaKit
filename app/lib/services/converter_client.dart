import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Falha de conversão já traduzida para uma frase que pode ir direto para a tela.
class ConverterException implements Exception {
  const ConverterException(this.message);

  final String message;

  @override
  String toString() => message;
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
      throw const ConverterException(
        'Endereço do servidor inválido. Ajuste em Perfil › Servidor de conversão.',
      );
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
      throw ConverterException(_describeTransportFailure(e, uri));
    }

    if (response.statusCode != 200) {
      throw ConverterException(_describeServerError(response));
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

  String _describeServerError(http.Response response) {
    // O backend responde `{ "error": "..." }` nos casos previstos.
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] is String) return body['error'] as String;
    } catch (_) {
      // Resposta que não é JSON: cai no texto genérico abaixo.
    }
    return 'O servidor não conseguiu converter o arquivo (HTTP ${response.statusCode}).';
  }

  String _describeTransportFailure(Exception e, Uri uri) {
    if (e is TimeoutException) {
      return 'A conversão passou de ${_timeout.inSeconds} segundos e foi '
          'cancelada. Tente de novo ou use um arquivo menor.';
    }
    if (e is SocketException || e is http.ClientException) {
      return 'Não foi possível falar com o servidor em ${uri.origin}. '
          'Verifique se ele está rodando e se o endereço está certo.';
    }
    return 'Falha ao enviar o arquivo para conversão: $e';
  }
}
