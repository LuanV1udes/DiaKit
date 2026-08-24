const fs = require('fs');
const os = require('os');
const path = require('path');
const express = require('express');
const multer = require('multer');
const { convert, convertToPdf } = require('../services/converter');

const router = express.Router();

const TMP_ROOT = path.join(__dirname, '..', '..', 'tmp');
fs.mkdirSync(TMP_ROOT, { recursive: true });

const upload = multer({ dest: TMP_ROOT });

// Word, Excel e PowerPoint, binario (97-2003) e OOXML -- tudo que o
// LibreOffice exporta para PDF sem perda estrutural.
const SUPPORTED_EXTENSIONS = ['.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'];

router.post('/to-pdf', upload.single('file'), async (req, res) => {
  if (!req.file) {
    res.status(400).json({ error: 'Envie um arquivo no campo "file".' });
    return;
  }

  const originalExt = path.extname(req.file.originalname).toLowerCase();
  if (!SUPPORTED_EXTENSIONS.includes(originalExt)) {
    fs.unlink(req.file.path, () => {});
    res.status(400).json({
      error: `Formato nao suportado. Envie um arquivo ${SUPPORTED_EXTENSIONS.join(', ')}`,
    });
    return;
  }

  const jobDir = fs.mkdtempSync(path.join(os.tmpdir(), 'diakit-'));
  const inputPath = path.join(jobDir, `input${originalExt}`);
  fs.renameSync(req.file.path, inputPath);

  try {
    const outputPath = await convertToPdf(inputPath, jobDir);
    const downloadName = `${path.basename(req.file.originalname, originalExt)}.pdf`;

    res.download(outputPath, downloadName, (err) => {
      fs.rm(jobDir, { recursive: true, force: true }, () => {});
      if (err && !res.headersSent) {
        res.status(500).json({ error: 'Falha ao enviar o PDF convertido.' });
      }
    });
  } catch (error) {
    fs.rm(jobDir, { recursive: true, force: true }, () => {});
    res.status(500).json({ error: error.message });
  }
});

// Cada formato de saida so aceita as entradas de onde faz sentido vir --
// evita alguem pedir "vira .csv" de um .docx, por exemplo.
const FORMAT_INPUTS = {
  xlsx: ['.csv'],
  csv: ['.xls', '.xlsx'],
};

router.post('/to-format', upload.single('file'), async (req, res) => {
  if (!req.file) {
    res.status(400).json({ error: 'Envie um arquivo no campo "file".' });
    return;
  }

  const target = String(req.body.target || '').toLowerCase();
  const acceptedInputs = FORMAT_INPUTS[target];
  if (!acceptedInputs) {
    fs.unlink(req.file.path, () => {});
    res.status(400).json({
      error: `Formato de destino nao suportado. Use um de: ${Object.keys(FORMAT_INPUTS).join(', ')}`,
    });
    return;
  }

  const originalExt = path.extname(req.file.originalname).toLowerCase();
  if (!acceptedInputs.includes(originalExt)) {
    fs.unlink(req.file.path, () => {});
    res.status(400).json({
      error: `Para gerar .${target}, envie um arquivo ${acceptedInputs.join(' ou ')}`,
    });
    return;
  }

  const jobDir = fs.mkdtempSync(path.join(os.tmpdir(), 'diakit-'));
  const inputPath = path.join(jobDir, `input${originalExt}`);
  fs.renameSync(req.file.path, inputPath);

  try {
    const outputPath = await convert(inputPath, jobDir, target);
    const downloadName = `${path.basename(req.file.originalname, originalExt)}.${target}`;

    res.download(outputPath, downloadName, (err) => {
      fs.rm(jobDir, { recursive: true, force: true }, () => {});
      if (err && !res.headersSent) {
        res.status(500).json({ error: 'Falha ao enviar o arquivo convertido.' });
      }
    });
  } catch (error) {
    fs.rm(jobDir, { recursive: true, force: true }, () => {});
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
