// R2.8: observabilidade — access log + x-request-id (Requisito F).
//
// O formato do log é CONTRATO (seção 8): <timestamp ISO> <method> <path> <status> <duration_ms>
// — idêntico ao que a python-api produzirá na R3. A comparação por agregação
// (quais rotas somam mais tempo em cada stack) só funciona se os campos casarem.
//
// O request-id é gerado SE AUSENTE — propagação vence sobre geração. É o que
// destrava o experimento: o terminal do detetive (R4) enviará o MESMO id às
// duas APIs, e os logs das duas passam a ser pareáveis (mesma jogada, par de traces).
//
// Métricas ficam FORA da v1 (decisão do card): p95 será medido na R5 por
// benchmark externo — não por métrica interna.
import { randomUUID } from 'node:crypto';

export function observabilidade(req, res, next) {
  const inicio = process.hrtime.bigint();

  // "se ausente": id do cliente é respeitado; sem id, um UUID v4 nasce aqui.
  const requestId = req.headers['x-request-id'] || randomUUID();
  res.setHeader('x-request-id', requestId);

  const duracaoMs = () => Number(process.hrtime.bigint() - inicio) / 1e6;

  // access log no "finish": pega o status REAL da resposta — inclusive
  // 404 de rota inexistente e 500 do error handler (middleware está
  // primeiro na cadeia, vê tudo que passa).
  res.on('finish', () => {
    const ts = new Date().toISOString();
    // originalUrl (path + query): serve a investigação ("a request divergente
    // tinha ?sexo=xxx") sem perder a agregação (agrupa-se por método+path)
    console.log(`${ts} ${req.method} ${req.originalUrl} ${res.statusCode} ${Math.round(duracaoMs())}ms`);
  });

  next();
}