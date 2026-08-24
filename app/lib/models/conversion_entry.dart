import 'dart:convert';

/// Desfecho de uma conversão, como aparece no Histórico.
enum ConversionStatus { success, error }

/// Que tipo de conversão gerou a entrada -- muda o que [outputPath] aponta e
/// como o Histórico reage ao toque na linha.
enum ConversionKind {
  /// [outputPath] é um único arquivo de saída -- PDF, XLSX, CSV, o que a
  /// conversão tiver gerado. O nome é histórico (a primeira conversão do
  /// app era só Office → PDF); o que importa para o Histórico é que é um
  /// arquivo só, abrível direto.
  officeToPdf,

  /// [outputPath] é a pasta com as imagens geradas a partir de um PDF.
  pdfToImages;

  /// Entradas gravadas antes deste campo existir não têm `kind` no JSON --
  /// todas elas eram conversões de arquivo único.
  static ConversionKind fromName(String? name) => ConversionKind.values
      .firstWhere((k) => k.name == name, orElse: () => officeToPdf);
}

/// Uma linha do Histórico: o que foi convertido, quando e como terminou.
class ConversionEntry {
  const ConversionEntry({
    required this.fileName,
    required this.at,
    required this.status,
    this.kind = ConversionKind.officeToPdf,
    this.outputPath,
    this.sizeBytes,
    this.pageCount,
    this.errorMessage,
  });

  /// Nome exibido: o `.pdf` gerado em caso de sucesso, o arquivo de origem
  /// quando a conversão falhou -- é o que o mockup mostra nas duas linhas.
  final String fileName;

  final DateTime at;
  final ConversionStatus status;
  final ConversionKind kind;

  /// Caminho do PDF ([ConversionKind.officeToPdf]) ou da pasta de imagens
  /// ([ConversionKind.pdfToImages]) gerados. Nulo quando [status] é
  /// [ConversionStatus.error].
  final String? outputPath;

  /// Tamanho do PDF, ou soma do tamanho de todas as imagens.
  final int? sizeBytes;

  /// Só para [ConversionKind.pdfToImages]: quantas páginas/imagens saíram.
  final int? pageCount;

  /// Motivo da falha, mostrado ao tocar na linha de erro.
  final String? errorMessage;

  Map<String, Object?> toJson() => {
    'fileName': fileName,
    'at': at.toIso8601String(),
    'status': status.name,
    'kind': kind.name,
    'outputPath': outputPath,
    'sizeBytes': sizeBytes,
    'pageCount': pageCount,
    'errorMessage': errorMessage,
  };

  static ConversionEntry fromJson(Map<String, Object?> json) => ConversionEntry(
    fileName: json['fileName'] as String,
    at: DateTime.parse(json['at'] as String),
    status: ConversionStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => ConversionStatus.error,
    ),
    kind: ConversionKind.fromName(json['kind'] as String?),
    // 'pdfPath' é o nome antigo do campo, de antes de existir pdfToImages.
    outputPath: (json['outputPath'] ?? json['pdfPath']) as String?,
    sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
    pageCount: (json['pageCount'] as num?)?.toInt(),
    errorMessage: json['errorMessage'] as String?,
  );

  String encode() => jsonEncode(toJson());

  static ConversionEntry decode(String raw) =>
      fromJson(jsonDecode(raw) as Map<String, Object?>);
}
