// O dicionário de pistas — contrato v1, seção 2.
// Fonte única: a borda (Zod), a seed e o schema Mongoose validam contra ESTE objeto.
export const DICIONARIO = {
  sexo:    ['masc', 'fem'],
  hobby:   ['tenis', 'musica', 'escalada', 'skydiving', 'natacao', 'cricket'],
  cabelo:  ['castanho', 'loiro', 'preto', 'ruivo'],
  traco:   ['manca', 'anel', 'joias', 'tatuagem', 'cicatriz'],
  veiculo: ['conversivel', 'limusine', 'motocicleta', 'carro de corrida'],
};

// A ordem de revelação das pistas — contrato v1, seção 6.1 (R2.5 usará)
export const ORDEM_REVELACAO = ['sexo', 'hobby', 'cabelo', 'traco', 'veiculo'];