import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

/// Falha ao rasterizar já traduzida para uma frase que pode ir direto para a
/// tela (PDF corrompido, senha, sem páginas etc.).
class RasterizeException implements Exception {
  const RasterizeException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Pasta com as imagens geradas e o que saiu nela.
class PdfImagesOutput {
  const PdfImagesOutput({
    required this.folder,
    required this.images,
    required this.totalBytes,
  });

  final Directory folder;

  /// Uma por página, na ordem do PDF.
  final List<File> images;

  final int totalBytes;

  int get pageCount => images.length;
}

/// Renderiza cada página de um PDF como PNG, direto no aparelho -- sem
/// depender do backend nem do LibreOffice, que só exportam a primeira
/// página de um PDF (testado: `soffice --convert-to png` de um PDF de 25
/// páginas gera um único PNG).
class PdfRasterizer {
  const PdfRasterizer();

  /// Pontos do PDF (1/72") multiplicados por isso viram pixels. 2.0 ≈ 144dpi,
  /// nítido o bastante para tela e impressão sem gerar arquivos enormes.
  static const _scale = 2.0;

  Future<PdfImagesOutput> convertToImages({
    required XFile file,
    void Function(int done, int total)? onProgress,
  }) async {
    final PdfDocument document;
    try {
      document = await PdfDocument.openData(await file.readAsBytes());
    } catch (e) {
      throw RasterizeException(
        'Não foi possível abrir esse PDF. Ele pode estar corrompido ou '
        'protegido por senha.',
      );
    }

    try {
      if (document.pagesCount == 0) {
        throw const RasterizeException('Esse PDF não tem nenhuma página.');
      }

      final docsDir = await getApplicationDocumentsDirectory();
      // file.name pode vir com o caminho inteiro em vez de só o nome -- o
      // cross_file so separa pelo separador nativo da plataforma (`\` no
      // Windows), entao um path com `/` passa direto. p.basename entende os
      // dois.
      final baseName = p.basenameWithoutExtension(file.name);
      final folder = Directory(
        '${docsDir.path}/${_uniqueFolderName(docsDir, baseName)}',
      );
      await folder.create(recursive: true);

      final digits = document.pagesCount.toString().length;
      final images = <File>[];
      var totalBytes = 0;

      for (var i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        try {
          final rendered = await page.render(
            width: page.width * _scale,
            height: page.height * _scale,
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );
          if (rendered == null) {
            throw RasterizeException(
              'Falha ao renderizar a página $i de ${document.pagesCount}.',
            );
          }

          final imageFile = File(
            '${folder.path}/pagina-${i.toString().padLeft(digits, '0')}.png',
          );
          await imageFile.writeAsBytes(rendered.bytes);
          images.add(imageFile);
          totalBytes += rendered.bytes.length;
        } finally {
          await page.close();
        }

        onProgress?.call(i, document.pagesCount);
      }

      return PdfImagesOutput(
        folder: folder,
        images: images,
        totalBytes: totalBytes,
      );
    } finally {
      await document.close();
    }
  }

  /// Evita misturar as imagens de duas conversões do mesmo arquivo — o
  /// Histórico aponta para a pasta antiga e ela precisa continuar intacta.
  String _uniqueFolderName(Directory dir, String baseName) {
    if (!Directory('${dir.path}/$baseName').existsSync()) return baseName;

    var attempt = 2;
    while (Directory('${dir.path}/$baseName ($attempt)').existsSync()) {
      attempt++;
    }
    return '$baseName ($attempt)';
  }
}
