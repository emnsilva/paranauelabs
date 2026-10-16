// O envelope de erro da casa — contrato v1, seção 5.
// { error, message, details } — o MESMO formato em toda resposta não-2xx.
// Uma única fonte: rotas importam daqui, nunca montam o objeto na mão.

export function erroValidacao(details, message = 'Requisição inválida.') {
  return { error: 'validation_error', message, details };
}

export function erroNaoEncontrado(message = 'Recurso não encontrado.') {
  return { error: 'not_found', message, details: [] };
}