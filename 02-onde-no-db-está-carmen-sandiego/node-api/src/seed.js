// ADR-002: seed única (data/seed.json) com carga idempotente.
// ADR-006: o contador nasce sincronizado com MAX — carga manual não avança gerador.
// R2.7: resetSeed — o reset determinístico (apaga casos, recarrega, ressincroniza).
// Startup e reset compartilham ESTE arquivo: um só caminho de carga (ADR-002).
import fs from 'node:fs';
import path from 'node:path';
import mongoose from 'mongoose';
import { DICIONARIO } from './dicionario.js';

// Os schemas Mongoose — validação de banco com o dicionário (segunda camada;
// a primeira é o Zod da borda nas rotas).
export const Criminal = mongoose.model('Criminal', new mongoose.Schema({
  id:        { type: Number, unique: true },
  codename:  { type: String, required: true },
  sexo:      { type: String, enum: DICIONARIO.sexo, required: true },
  hobby:     { type: String, enum: DICIONARIO.hobby, required: true },
  cabelo:    { type: String, enum: DICIONARIO.cabelo, required: true },
  traco:     { type: String, enum: DICIONARIO.traco, required: true },
  veiculo:   { type: String, enum: DICIONARIO.veiculo, required: true },
}, { versionKey: false }));

export const City = mongoose.model('City', new mongoose.Schema({
  id:       { type: Number, unique: true },
  name:     { type: String, required: true },
  country:  { type: String, required: true },
  landmark: { type: String, required: true },
  loot:     { type: String, required: true },
}, { versionKey: false }));

const Counter = mongoose.model('Counter', new mongoose.Schema({
  _id:  String,
  seq:  Number,
}, { versionKey: false }));

// Validação da seed ANTES de inserir (mitigação do ADR-002):
// enum fora do dicionário ou 5-tupla duplicada derruba o startup — na hora, na cara.
function validarSeed(criminals) {
  const vistas = new Set();
  for (const c of criminals) {
    for (const [campo, valores] of Object.entries(DICIONARIO)) {
      if (!valores.includes(c[campo])) {
        throw new Error(`seed invalida: ${c.codename}.${campo}="${c[campo]}" fora do dicionario`);
      }
    }
    const tupla = `${c.sexo}|${c.hobby}|${c.cabelo}|${c.traco}|${c.veiculo}`;
    if (vistas.has(tupla)) {
      throw new Error(`seed invalida: 5-tupla duplicada (${tupla}) — o mandado bateria com dois suspeitos`);
    }
    vistas.add(tupla);
  }
}

// Carrega a seed se o banco estiver vazio — e ressincroniza o contador sempre.
// Idempotente de verdade: banco populado => nada insere, log diz por quê.
export async function carregarSeed() {
  const seed = JSON.parse(fs.readFileSync(path.resolve('/app/seed.json'), 'utf8'));

  const nCriminals = await Criminal.countDocuments({});
  const nCities = await City.countDocuments({});

  if (nCriminals === 0 && nCities === 0) {
    validarSeed(seed.criminals);
    await Criminal.insertMany(seed.criminals);
    await City.insertMany(seed.cities);
    console.log(`[seed] carregada: ${seed.criminals.length} bandidos, ${seed.cities.length} cidades`);
  } else {
    console.log(`[seed] ignorada (banco populado: ${nCriminals} bandidos, ${nCities} cidades)`);
  }

  await sincronizarContador();
}

// R2.7: o reset determinístico — o ponto de partida da suíte R4.
// Apaga CASOS (investigações são descartáveis), recarrega o dossiê do zero
// e ressincroniza o contador. O MESMO caminho de código do startup (ADR-002):
// não existe segundo carregador.
export async function resetSeed() {
  const seed = JSON.parse(fs.readFileSync(path.resolve('/app/seed.json'), 'utf8'));

  const casosApagados = await mongoose.connection.dropCollection('cases')
    .then(() => true)
    .catch(() => false);   // coleção inexistente: nada a apagar

  await Criminal.deleteMany({});
  await City.deleteMany({});
  validarSeed(seed.criminals);
  await Criminal.insertMany(seed.criminals);
  await City.insertMany(seed.cities);

  await sincronizarContador();

  return {
    status: 'reset',
    criminals: seed.criminals.length,
    cities: seed.cities.length,
    cases_deleted: casosApagados,
  };
}

// ADR-006: ressincroniza o contador com o MAX — sempre.
async function sincronizarContador() {
  const ultimo = await Criminal.findOne({}).sort({ id: -1 });
  const max = ultimo ? ultimo.id : 0;
  await Counter.findByIdAndUpdate(
    { _id: 'criminals' },
    { $set: { seq: max } },
    { upsert: true }
  );
  console.log(`[seed] contador sincronizado com MAX(id) = ${max}`);
}