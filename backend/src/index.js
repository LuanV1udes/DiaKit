const express = require('express');
const { isConverterReady, engineName } = require('./services/converter');
const convertRouter = require('./routes/convert');

const app = express();
const PORT = process.env.PORT || 4123;

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    converter: isConverterReady() ? 'disponivel' : 'nao encontrado',
    engine: engineName(),
  });
});

app.use('/convert', convertRouter);

app.listen(PORT, () => {
  console.log(`DiaKit backend rodando em http://localhost:${PORT}`);
});
