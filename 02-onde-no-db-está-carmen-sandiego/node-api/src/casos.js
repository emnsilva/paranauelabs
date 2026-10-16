// R2.5: a abertura de casos — modelagem documental + sorteio + paraPublico.
// ADR-003: a resposta mora no banco desde o sorteio; paraPublico é a ÚNICA
// função que transforma documento em resposta (um só lugar pra esquecer de esconder).
import mongoose from 'mongoose';
import { Criminal, City } from './seed.js';
import { ORDEM_REVELACAO } from './dicionario.js';

// O documento do caso — a modelagem documental (contrato seção 3):
// itinerary embutido (o que no relacional seria tabela clues + FK) e
// warrant nascendo null (o que lá seria tabela 1:1 com UNIQUE).
export const Case = mongoose.model('Case', new mongoose.Schema({
  case_number: { type: String, unique: true },
  crime:       { type: String, required: true },
  stolen_item: { type: String, required: true },
  status:      { type: String, enum: ['open', 'solved'], default: 'open' },
  culprit_id:  { type: Number, required: true },   // <- A RESPOSTA (nunca sai pública)
  wrong_travels: { type: Number, default: 0 },
  itinerary: [{
    city:          String,
    country:       String,
    landmark:      String,
    testimony:     String,
    revealed_trait: String,
    discovered:    { type: Boolean, default: false },
  }],
  warrant: {
    sexo:    String, hobby: String, cabelo: String,
    traco:   String, veiculo: String, issued_at: Date,
  },
  opened_at: { type: Date, default: Date.now },
}, { versionKey: false }));

// O sorteio (contrato seção 6.1). Três regras com nome:
// 1. culpado entre capangas (Carmen id 1 é a chefa — fora de v1);
// 2. itinerário de 5 cidades DISTINTAS (embaralha e toma 5);
// 3. cidade i revela a característica i, na ordem fixa do contrato.
export async function sortearCaso() {
  // 1. culpado: aggregation $sample pega um documento aleatório — em
  // coleção pequena é simples e correto (nota didática registrada no card R2.5).
  const [culprit] = await Criminal.aggregate([
    { $match: { id: { $ne: 1 } } },   // Carmen fora do sorteio
    { $sample: { size: 1 } },
  ]);

  // 2. itinerário: todas as cidades, embaralha, toma 5. A 1ª é a cena do crime.
  const todas = await City.find({}).sort({ id: 1 });
  const embaralhadas = [...todas].sort(() => Math.random() - 0.5);
  const rota = embaralhadas.slice(0, 5);

  // 3. crime deriva do loot+landmark da 1ª cidade (contrato: "Roubou {loot} de {landmark}")
  const cena = rota[0];
  const crime = `Roubou ${cena.loot} de ${cena.landmark}`;

  // 4. o itinerário completo, com a característica de cada cidade NA ORDEM do contrato.
  //    O texto da testemunha interpola a característica do culpado na posição i.
  const itinerary = rota.map((cidade, i) => {
    const campo = ORDEM_REVELACAO[i];
    const valor = culprit[campo];
    return {
      city: cidade.name,
      country: cidade.country,
      landmark: cidade.landmark,
      testimony: `A testemunha viu: ${campo} ${valor}. Fugiu rumo a ${rota[i + 1]?.name ?? 'destino desconhecido'}.`,
      revealed_trait: `${campo}: ${valor}`,
      discovered: i === 0,   // só a cena do crime começa descoberta
    };
  });

  return { culprit, crime, stolen_item: cena.loot, itinerary };
}

// O número do caso: CASE-YYYY-NNN — sequência anual própria (ADR-006:
// casos NÃO usam o contador de criminals; case_number é legível por design).
export async function gerarCaseNumber() {
  const ano = new Date().getFullYear();
  const total = await Case.countDocuments({
    case_number: { $regex: `^CASE-${ano}-` },
  });
  const n = String(total + 1).padStart(3, '0');
  return `CASE-${ano}-${n}`;
}

// paraPublico: A ÚNICA porta de saída do caso (ADR-003).
// - só pistas com discovered: true
// - heading_to: a PRÓXIMA PARADA do itinerário (o destino da fuga — público
//   desde que a testemunha falou), null apenas na última pista (trilha esgotada)
// - warrant: null quando não emitido (nunca {})
// - culprit_id: NUNCA (só codinome, e só se solved — R2.7)
export function paraPublico(doc) {
  const indicesDescobertos = doc.itinerary
    .map((p, i) => (p.discovered ? i : -1))
    .filter((i) => i >= 0);

  const descobertas = indicesDescobertos.map((i) => ({
    city: doc.itinerary[i].city,
    testimony: doc.itinerary[i].testimony,
    revealed_trait: doc.itinerary[i].revealed_trait,
    // a próxima parada: existe cidade i+1 no itinerário? é ela. Não existe (5ª pista)? null.
    heading_to: doc.itinerary[i + 1]?.city ?? null,
  }));

  return {
    case_number: doc.case_number,
    crime: doc.crime,
    stolen_item: doc.stolen_item,
    status: doc.status,
    clues: descobertas,
    wrong_travels: doc.wrong_travels,
    // warrant vazio do Mongoose (sem campos preenchidos) => null público.
    // R2.7 preencherá os campos; enquanto o campo sentinela estiver vazio, é null.
    warrant: (doc.warrant && doc.warrant.sexo) ? doc.warrant : null,
    opened_at: doc.opened_at,
  };
}