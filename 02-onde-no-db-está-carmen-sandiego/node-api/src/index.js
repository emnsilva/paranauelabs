// R2.8: observabilidade PRIMEIRO na cadeia — request que não casa rota
// nenhuma também é evento observável.
import express from 'express';
import { conectar } from './db.js';
import { carregarSeed, resetSeed } from './seed.js';
import { observabilidade } from './observabilidade.js';
import criminals from './rotas/criminals.js';
import cities from './rotas/cities.js';
import casos from './rotas/casos.js';

const app = express();
const PORT = process.env.PORT || 7421;

app.use(observabilidade);   // primeiro: cronômetro e id valem para TUDO
app.use(express.json());
app.use(criminals);
app.use(cities);
app.use(casos);

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', api: 'node-api' });
});

// POST /api/seed — o reset determinístico (ponto de partida da suíte R4).
app.post('/api/seed', async (_req, res, next) => {
  try {
    const resultado = await resetSeed();
    res.json(resultado);
  } catch (err) {
    next(err);
  }
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