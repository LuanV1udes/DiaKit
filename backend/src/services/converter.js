const libreoffice = require('./libreoffice');

function isConverterReady() {
  return libreoffice.isConverterReady();
}

function engineName() {
  return libreoffice.isConverterReady() ? 'libreoffice' : null;
}

function ensureReady() {
  if (!libreoffice.isConverterReady()) {
    throw new Error(
      'LibreOffice nao encontrado. Instale o LibreOffice ou defina a variavel de ambiente '
      + 'SOFFICE_PATH apontando para o soffice.exe, e rode a conversao de novo.'
    );
  }
}

async function convertToPdf(inputPath, outputDir) {
  ensureReady();
  return libreoffice.convertToPdf(inputPath, outputDir);
}

async function convert(inputPath, outputDir, targetFormat) {
  ensureReady();
  return libreoffice.convert(inputPath, outputDir, targetFormat);
}

module.exports = { convert, convertToPdf, isConverterReady, engineName };
