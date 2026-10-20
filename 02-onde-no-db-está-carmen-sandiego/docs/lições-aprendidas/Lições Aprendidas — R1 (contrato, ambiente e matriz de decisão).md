A R1 produziu poucos incidentes — e isso é dado, não omissão: contrato definido antes do código e ambiente varrido antes do build eliminaram classes inteiras de falha antes de elas existirem. Os incidentes que houve, e os riscos que a verificação cortou no nascedouro, estão aqui. As lições de processo (entrega, ritual, falsos verdes) nasceram na R2 e vivem em Lições Aprendidas — R2 (node-api: mecânica, instrumentação, testes).md.

**1 — Erro de digitação na seed ("limusicleta")**<br>
**Erro:** valor híbrido "limusicleta" no seed.json — limusine fundida com bicicleta no veículo de um dos 21 bandidos.<br>
**Causa:** digitação manual da seed inteira, sem validação automática de domínio nos valores.<br>
**Solução:** correção + re-semeadura conferida — e os números da seed viraram ASSERTS: todo reset reporta criminals:20, cities:12, e a collection da R2 confere os dois. Dividendo colhido na R2: um erro de digitação novo na seed agora seria detectado (o teste quebraria). Extensão natural no backlog v2: validador de seed contra os domínios do dicionário.<br>

**2 — Distro escolhida por inércia (interceptada pelo sweep)**<br>
**Erro (evitado por verificação):** o Ubuntu estava no radar como escolha "natural" — eliminado no sweep, com o motivo documentado.<br>
**Causa:** heterogeneidade de ambiente: o que sobe numa distro sobe diferente (ou não sobe) na outra; a escolha por familiaridade é chute disfarçado de decisão.<br>
**Solução:** sweep com 4 distros ANTES de qualquer Dockerfile. Ambiente se testa, não se assume.<br>

**3 — .env.example inexistente (buraco de nove atividades)**<br>
**Erro (latente):** o make up faz cp .env.example .env — sem o template, o bootstrap de um clone fresco quebra na primeira execução.<br>
**Causa:** o .env sempre esteve à mão na VM; o caminho do clone limpo nunca foi exercitado. Origem na R1 (o Makefile é dela); descoberto apenas na R2.10 — o buraco permaneceu invisível por nove atividades.<br>
**Solução:** template completo no repo (política repo-only), com todas as versões pinadas (incluindo a BRUNO_CLI_VERSION; ver lição R2-8). A mesma lição vale para qualquer arquivo que o bootstrap assume presente: assumir presença sem exercitar o caminho do zero é falha esperando hora marcada.<br>

## Erros evitados pela fundação (por que a R1 é curta)

**4 — Renegociação de contrato no meio do build**<br>
**Erro evitado:** descobrir na R2.x que o contrato não fechava, com metade da API pronta.<br>
**Causa do risco:** contrato definido junto com o código deriva — cada endpoint empurra o shape na direção do que é fácil implementar.<br>
**Solução:** contrato v1 (OpenAPI + narrativo) e seed congelados ANTES de qualquer linha de API. Recibo: 11 atividades de R2 sem uma única renegociação; quando a R2.9 precisou de asserts, eles saíram do contrato; quando o smoke precisou de shape, saiu do contrato.<br>

**5 — Resposta vazando o culpado**<br>
**Erro evitado:** anti-spoiler como preocupação tardia de revisão.<br>
**Causa do risco:** "quem é o culpado" mora no banco desde o sorteio — qualquer serialização descuidada entrega o jogo.<br>
**Solução:** ADR-003 transformando anti-spoiler em requisito FUNCIONAL. Uma cadeia que só existiu porque a decisão foi escrita primeiro: ADR (R1) → serialização própria paraPublico() (R2.5) → assert de corpo real (R2.9).<br>

**6 — Bootstrap quebrando em banco sujo**<br>
**Erro evitado:** contador fora de sincronia com os dados após qualquer estado parcial do banco.<br>
**Causa do risco:** idempotência é fácil de prometer e fácil de quebrar em edge cases (banco pela metade, re-semeadura parcial).<br>
**Solução:** ADR-002/006 — seed idempotente + contador ressincronizado com MAX(id) em qualquer estado. Recibo em runtime, na R2: o log do container [seed] contador sincronizado com MAX(id) = 20 após reset com caso em andamento. E os cenários de persistência A/B/C validados na R1, ANTES de qualquer API existir — fundação testada antes de construir em cima.<br>

**7 — Divergência silenciosa entre as stacks**<br>
**Erro evitado:** paridade por CÓPIA — duas suítes de teste separadas, cada uma aprovando sua API, divergindo em detalhes que ninguém nota.<br>
**Causa do risco:** o lab compara stacks; se cada stack nasce com seus próprios artefatos de teste, a comparação perde a régua comum.<br>
**Solução:** contrato ÚNICO e seed ÚNICA definidos na R1 — paridade por HERANÇA. Completada na R2.9 com a collection no nível do LAB (não dentro de node-api/): a python-api da R3 será validada pela MESMA suíte, trocando apenas a base_url.<br>

**8 — Var de ambiente faltante explodindo em runtime misterioso**<br>
**Erro evitado:** compose com defaults — var ausente vira valor silencioso, e o erro aparece três camadas adiante, sem pista.<br>
**Causa do risco:** default é conveniente na máquina de quem escreveu e é armadilha na de quem clonou.<br>
**Solução:** zero-default no compose (convenção: .env obrigatório) + docker compose config --quiet no ritual de toda entrega — var faltante estoura ALTO e CEDO, na conferência, nunca em runtime.<br>

## Notas de infra que nasceram prontas (sem incidentes para contá-las)
- Todas as portas no .env (BIND_HOST=127.0.0.1, externa ≠ interna quando necessário); nenhuma fixada em YAML.
- Healthchecks + --wait: "container started" ≠ "pronto para servir" — o bootstrap da API depende de o banco estar pronto de verdade.
- .RECIPEPREFIX = >: TAB não sobrevive a cópia/cola entre canais. O Makefile precisou ser reproduzível de qualquer origem — e foi, em todas as entregas da R1 e da R2. (A prova de conceito virou régua na R2.)
