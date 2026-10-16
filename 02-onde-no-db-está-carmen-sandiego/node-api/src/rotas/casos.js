// R2.6/R2.7: casos completos — abertura, viagens, leitura, mandado.
// O anti-spoiler em tempo real: paraPublico é a única porta de saída.
// Mandado: acerto revela codinome; erro SEM DICA (fiel ao original de 1985).
import { Router } from 'express';
import { z } from 'zod';
import { Case, sortearCaso, gerarCaseNumber, paraPublico } from '../casos.js';
import { Criminal, City } from '../seed.js';
import { DICIONARIO } from '../dicionario.js';
import { erroValidacao, erroNaoEncontrado } from '../erros.js';

const router = Router();

// POST /cases — o jogo começa (R2.5).
router.post('/cases', async (_req, res, next) => {
  try {
    const { culprit, crime, stolen_item, itinerary } = await sortearCaso();
    const case_number = await gerarCaseNumber();

    const doc = await Case.create({
      case_number,
      crime,
      stolen_item,
      status: 'open',
      culprit_id: culprit.id,
      wrong_travels: 0,
      itinerary,
    });

    res.status(201).json(paraPublico(doc));
  } catch (err) {
    next(err);
  }
});

const RE_CASE_NUMBER = /^CASE-\d{4}-\d{3}$/;

// POST /cases/:case_number/travel — viajar e desbloquear a próxima pista (R2.6).
const CorpoViagem = z.object({
  city: z.string().min(1),
});

router.post('/cases/:case_number/travel', async (req, res, next) => {
  try {
    if (!RE_CASE_NUMBER.test(req.params.case_number)) {
      return res.status(400).json(erroValidacao([
        { field: 'case_number', issue: 'deve estar no formato CASE-YYYY-NNN' },
      ]));
    }

    const parse = CorpoViagem.safeParse(req.body);
    if (!parse.success) {
      return res.status(400).json(erroValidacao(
        parse.error.issues.map((i) => ({ field: i.path.join('.'), issue: 'obrigatório' }))
      ));
    }

    const doc = await Case.findOne({ case_number: req.params.case_number });
    if (!doc) {
      return res.status(404).json(erroNaoEncontrado('Caso não encontrado.'));
    }

    if (doc.status === 'solved') {
      return res.status(409).json({
        error: 'conflict', message: 'Caso já resolvido.', details: [],
      });
    }

    const cidadeExiste = await City.exists({ name: parse.data.city });
    if (!cidadeExiste) {
      return res.status(400).json(erroValidacao([
        { field: 'city', issue: 'cidade fora do catálogo' },
      ]));
    }

    const proximoIndice = doc.itinerary.findIndex((p) => !p.discovered);

    if (proximoIndice === -1) {
      return res.json({
        status: 'open',
        message: 'A trilha acabou. Emitir um mandado.',
        wrong_travels: doc.wrong_travels,
      });
    }

    if (doc.itinerary[proximoIndice].city === parse.data.city) {
      doc.itinerary[proximoIndice].discovered = true;
      await doc.save();
      return res.json(paraPublico(doc));
    }

    doc.wrong_travels += 1;
    await doc.save();
    return res.json({
      status: 'open',
      message: 'As testemunhas não viram nada por aqui.',
      wrong_travels: doc.wrong_travels,
    });
  } catch (err) {
    next(err);
  }
});

// POST /cases/:case_number/warrant — o clímax (R2.7).
// As 5 características contra o culpado gravado desde a abertura.
const CorpoMandado = z.object({
  sexo:    z.enum(DICIONARIO.sexo),
  hobby:   z.enum(DICIONARIO.hobby),
  cabelo:  z.enum(DICIONARIO.cabelo),
  traco:   z.enum(DICIONARIO.traco),
  veiculo: z.enum(DICIONARIO.veiculo),
});

router.post('/cases/:case_number/warrant', async (req, res, next) => {
  try {
    if (!RE_CASE_NUMBER.test(req.params.case_number)) {
      return res.status(400).json(erroValidacao([
        { field: 'case_number', issue: 'deve estar no formato CASE-YYYY-NNN' },
      ]));
    }

    // validação das 5 características — mesmos enums do dossiê, detalhe por campo.
    const parse = CorpoMandado.safeParse(req.body);
    if (!parse.success) {
      const details = parse.error.issues.map((i) => ({
        field: i.path.join('.'),
        issue: 'valor fora do dicionário de pistas',
      }));
      return res.status(400).json(erroValidacao(details));
    }

    const doc = await Case.findOne({ case_number: req.params.case_number });
    if (!doc) {
      return res.status(404).json(erroNaoEncontrado('Caso não encontrado.'));
    }

    if (doc.status === 'solved') {
      return res.status(409).json({
        error: 'conflict', message: 'Caso já resolvido.', details: [],
      });
    }

    // o culpado está no banco desde a abertura (ADR-003) — a comparação é contra ele.
    const culpado = await Criminal.findOne({ id: doc.culprit_id });

    // o warrant fica gravado em QUALQUER resultado (o juiz registra a tentativa).
    doc.warrant = { ...parse.data, issued_at: new Date() };

    const acertou =
      culpado.sexo === parse.data.sexo &&
      culpado.hobby === parse.data.hobby &&
      culpado.cabelo === parse.data.cabelo &&
      culpado.traco === parse.data.traco &&
      culpado.veiculo === parse.data.veiculo;

    if (acertou) {
      doc.status = 'solved';
      await doc.save();
      // a revelação: codinome (nunca o id) — a única vitória do jogo.
      return res.json({
        status: 'solved',
        case_number: doc.case_number,
        culprit_codename: culpado.codename,
      });
    }

    // erro: SEM DICA do que errou — fiel ao original. O caso segue aberto.
    await doc.save();
    return res.json({
      status: 'open',
      message: 'O juiz rejeitou o mandado. Continue investigando.',
    });
  } catch (err) {
    next(err);
  }
});

// GET /cases/:case_number — o estado público do caso (R2.6).
router.get('/cases/:case_number', async (req, res, next) => {
  try {
    if (!RE_CASE_NUMBER.test(req.params.case_number)) {
      return res.status(400).json(erroValidacao([
        { field: 'case_number', issue: 'deve estar no formato CASE-YYYY-NNN' },
      ]));
    }

    const doc = await Case.findOne({ case_number: req.params.case_number });
    if (!doc) {
      return res.status(404).json(erroNaoEncontrado('Caso não encontrado.'));
    }

    // caso resolvido inclui o codinome (a revelação pós-vitória).
    const resposta = paraPublico(doc);
    if (doc.status === 'solved') {
      const culpado = await Criminal.findOne({ id: doc.culprit_id });
      resposta.culprit_codename = culpado.codename;
    }
    res.json(resposta);
  } catch (err) {
    next(err);
  }
});

export default router;