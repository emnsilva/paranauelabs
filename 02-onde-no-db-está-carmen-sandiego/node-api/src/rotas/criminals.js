// R2.3: o dossiê. Estabelece os padrões que R2.4-R2.7 herdam:
// Zod na borda -> filtro combinável -> projeção pública -> 400/404 com envelope.
import { Router } from 'express';
import { z } from 'zod';
import { Criminal } from '../seed.js';
import { DICIONARIO } from '../dicionario.js';
import { erroValidacao, erroNaoEncontrado } from '../erros.js';

const router = Router();

// A projeção pública: exatamente os campos do contrato, nada além
// (nem _id do Mongo — o id público é o inteiro; ADR-003 em versão dossiê).
const PROJECAO = { _id: 0, id: 1, codename: 1, sexo: 1, hobby: 1, cabelo: 1, traco: 1, veiculo: 1 };

// O schema de query: cada param é enum do dicionário, tudo opcional.
const QueryDossie = z.object({
  sexo:    z.enum(DICIONARIO.sexo).optional(),
  hobby:   z.enum(DICIONARIO.hobby).optional(),
  cabelo:  z.enum(DICIONARIO.cabelo).optional(),
  traco:   z.enum(DICIONARIO.traco).optional(),
  veiculo: z.enum(DICIONARIO.veiculo).optional(),
});

// GET /criminals — o dossiê, com filtros combináveis em AND.
router.get('/criminals', async (req, res, next) => {
  try {
    // validação na borda: a query inteira contra o schema, de uma vez.
    const parse = QueryDossie.safeParse(req.query);
    if (!parse.success) {
      // detalhe por campo: um item por campo rejeitado.
      const details = parse.error.issues.map((i) => ({
        field: i.path.join('.'),
        issue: 'valor fora do dicionário de pistas',
      }));
      return res.status(400).json(erroValidacao(details));
    }

    // filtro: só os campos presentes e válidos (sem undefined no find).
    const filtro = Object.fromEntries(
      Object.entries(parse.data).filter(([, v]) => v !== undefined)
    );

    const criminals = await Criminal.find(filtro, PROJECAO).sort({ id: 1 });
    res.json(criminals);
  } catch (err) {
    next(err);
  }
});

// GET /criminals/:id — a ficha de um suspeito.
router.get('/criminals/:id', async (req, res, next) => {
  try {
    // id não-numérico => 400 de validação (formato errado é requisição errada,
    // não recurso inexistente — a distinção 400/404 do contrato, seção 5).
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json(erroValidacao([{ field: 'id', issue: 'deve ser um inteiro' }]));
    }

    const criminal = await Criminal.findOne({ id }, PROJECAO);
    if (!criminal) {
      return res.status(404).json(erroNaoEncontrado('Suspeito não encontrado.'));
    }
    res.json(criminal);
  } catch (err) {
    next(err);
  }
});

export default router;