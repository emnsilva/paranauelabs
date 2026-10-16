// R2.4: o catálogo de cidades. O endpoint mais simples da API — e o
// teste de fumaça natural de qualquer mudança (se /cities responde, o
// pipeline request->rota->banco->resposta está são).
// Reaproveita integralmente os padrões da R2.3: projeção, ordenação, envelope.
import { Router } from 'express';
import { City } from '../seed.js';

const router = Router();

// Projeção pública: os campos do contrato (seção 4.5). Sem country_id —
// a normalização com tabela countries é solução do lado relacional;
// no documental, o país viaja como string. Cada paradigma canônico na sua.
const PROJECAO = { _id: 0, id: 1, name: 1, country: 1, landmark: 1, loot: 1 };

// GET /cities — as 12 cidades, ordenadas por id. Sem filtros na v1
// (candidato de backlog: filtros por país).
router.get('/cities', async (_req, res, next) => {
  try {
    const cities = await City.find({}, PROJECAO).sort({ id: 1 });
    res.json(cities);
  } catch (err) {
    next(err);
  }
});

export default router;