// R2.3: rotas no app + error handler central.
// Ordem do bootstrap segue contrato informal: conectar -> seed -> escutar.
import express from 'express';
import { conectar } from './db.js';
import { carregarSeed } from './seed.js';
import criminals from './rotas/criminals.js';

const app = express();
const PORT = process.env.PORT || 7421;

app.use(express.json());
app.use(criminals);

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', api: 'node-api' });
});

// Error handler central: tudo que escapar das rotas vira envelope 500.
app.use((err, _req, res, _next) => {
  console.error('[erro]', err.message);
  res.status(500).json({ error: 'internal_error', message: 'Erro interno.', details: [] });
});

const server = app.listen(PORT, () => {
  console.log(`node-api na porta ${PORT}`);
});

conectar()
  .then(carregarSeed)
  .catch((err) => {
    console.error('[bootstrap] falhou:', err.message);
    process.exit(1);
  });