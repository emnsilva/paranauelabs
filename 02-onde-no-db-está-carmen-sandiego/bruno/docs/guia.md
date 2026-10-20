Guia da collection — Carmen Sandiego (paridade de stacks)
Esta collection vive no nível do lab porque o contrato é único: os mesmosrequests servem à node-api hoje e à python-api no futuro (R3). Paridadevira consequência — não cópia: bastará criar environments/python.bruapontando base_url para a porta dela.

Abrir (desktop + túnel SSH)
Túnel na sua máquina: ssh -N -L 7421:127.0.0.1:7421 <sua-vm>
Bruno desktop → Collections → Open Collection → pasta bruno/
Selecione o ambiente node (canto superior direito)
Ambientes
Ambiente	base_url	Uso
node	http://127.0.0.1:7421	desktop via túnel (manual)
node-container	http://node-api:7421	CLI Bruno na rede do compose (R2.10)
Ordem de execução
A pasta casos é um fluxo encadeado — rode pelo Runner na ordem:

01-abrir (captura case_id) → 02-detalhar (captura cidade_atual)→ 03-viajar → 04-mandado-errado → 05-reset (fecha o ciclo: re-executável)

As demais pastas (health/criminals/cities) são independentes — qualquerordem serve. Rodando a coleção inteira, tudo verde.

O que a collection prova
Req. F em cada request: collection.bru gera x-request-id(prefixo bru-) e todo test confere o eco. O health demonstra apropagação com id fixo (detetive-bruno-001) voltando idêntico.
Anti-spoiler (ADR-003): o detalhe do caso não pode citar o culpado.
Seed como fato: 20 bandidos, 12 cidades; o filtro de exemploafunila em exatamente 1 suspeito.
Mandado errado: rejeição de negócio SEM dica (200, sem pista).
Jogar a caçada completa (manual)
O loop de prisão segue no smoke-test.sh (dinâmico com jq). Para jogarno Bruno: repita 03-viajar (cada viagem revela uma pista), anote ascaracterísticas, ajuste os filtros em criminals/filtrar-dossie e emitao mandado com o suspeito_id capturado pelo filtro.

Troubleshooting
409 no viajar: o caso nasceu em cidade_destino. Troque a var noambiente (ex.: use a cidade_alternativa) — ou aproveite o 409 comodemo do contrato.
400 no detalhar/viajar/mandado: rode a pasta casos na ordem — ocase_id vem do 01-abrir.
Porta interna diferente no container: confira comdocker compose -f docker-compose.yml -f api-compose.yml exec node-api printenv | grep -i porte ajuste o base_url do ambiente node-container.
Higiene do git: se o desktop persistir case_id/suspeito_id nosarquivos de ambiente, reverta antes do commit:`git checkout -- bruno/environments