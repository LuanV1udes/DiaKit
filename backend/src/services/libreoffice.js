const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFile, execFileSync } = require('child_process');

// Copia embutida no proprio pacote do DiaKit -- gerada por
// scripts/fetch-libreoffice.ps1, nunca commitada (1,5GB). Prioridade sobre o
// LibreOffice do sistema: e a que garante conversao sem exigir que o
// usuario instale nada a parte.
const BUNDLED_SOFFICE = path.join(__dirname, '..', '..', 'vendor', 'libreoffice', 'program', 'soffice.exe');

const CANDIDATE_PATHS = [
  BUNDLED_SOFFICE,
  process.env.SOFFICE_PATH,
  'C:\\Program Files\\LibreOffice\\program\\soffice.exe',
  'C:\\Program Files (x86)\\LibreOffice\\program\\soffice.exe',
].filter(Boolean);

// Perfil compartilhado entre chamadas: criar um do zero custa ~10s (o
// LibreOffice grava toda a config inicial), e isso rodaria a cada conversao
// se cada uma usasse seu proprio perfil. Reaproveitado, so a primeira
// conversao depois de o backend subir paga esse custo.
const SHARED_PROFILE_DIR = path.join(os.tmpdir(), 'diakit-lo-profile');

// Duas instancias do LibreOffice não podem escrever no mesmo perfil ao mesmo
// tempo (a segunda trava esperando o lock da primeira). Como o perfil agora
// e compartilhado, serializamos as conversoes aqui em vez de isolar por
// chamada -- so, na pratica, a Home so deixa 1 conversao em andamento por
// vez de qualquer forma.
let queue = Promise.resolve();

function isOnPath(command) {
  try {
    const finder = process.platform === 'win32' ? 'where' : 'which';
    execFileSync(finder, [command], { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

function findSofficeBinary() {
  for (const candidate of CANDIDATE_PATHS) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }
  return isOnPath('soffice') ? 'soffice' : null;
}

function isConverterReady() {
  return findSofficeBinary() !== null;
}

function runConversion(soffice, inputPath, outputDir, targetFormat) {
  return new Promise((resolve, reject) => {
    const args = [
      '--headless',
      '--norestore',
      `-env:UserInstallation=file:///${SHARED_PROFILE_DIR.replace(/\\/g, '/')}`,
      '--convert-to', targetFormat,
      '--outdir', outputDir,
      inputPath,
    ];

    // 120s cobre tanto a inicializacao do perfil na primeira chamada quanto
    // documentos grandes com muitas imagens.
    execFile(soffice, args, { timeout: 120_000 }, (error, stdout, stderr) => {
      if (error) {
        reject(new Error(`Falha ao converter arquivo: ${stderr || error.message}`));
        return;
      }

      const base = path.basename(inputPath, path.extname(inputPath));
      // targetFormat pode vir com opcoes de filtro depois de ":" (ex.:
      // "csv:Text - txt - csv (StarCalc)"); o soffice sempre usa so a parte
      // antes dos ":" como extensao do arquivo de saida.
      const extension = targetFormat.split(':')[0];
      const outputPath = path.join(outputDir, `${base}.${extension}`);

      if (!fs.existsSync(outputPath)) {
        reject(new Error('Conversao concluida mas o arquivo de saida nao foi encontrado.'));
        return;
      }

      resolve(outputPath);
    });
  });
}

function convert(inputPath, outputDir, targetFormat) {
  const soffice = findSofficeBinary();
  if (!soffice) {
    return Promise.reject(new Error(
      'LibreOffice nao encontrado. Instale o LibreOffice ou defina a variavel de ambiente SOFFICE_PATH apontando para o soffice.exe'
    ));
  }

  const job = queue.then(() => runConversion(soffice, inputPath, outputDir, targetFormat));
  // Continua a fila mesmo se esta conversao falhar -- o proximo pedido nao
  // pode ficar preso esperando um job que ja deu erro.
  queue = job.catch(() => {});
  return job;
}

function convertToPdf(inputPath, outputDir) {
  return convert(inputPath, outputDir, 'pdf');
}

module.exports = { convert, convertToPdf, isConverterReady, findSofficeBinary };
