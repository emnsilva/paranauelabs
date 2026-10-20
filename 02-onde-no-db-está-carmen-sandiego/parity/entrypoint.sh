#!/bin/sh
# Runner de paridade — executa a collection Bruno contra as APIs do lab.
#
# /src  -> collection montada do repo (somente leitura)
# /work -> cópia descartável. O CLI persiste vars de runtime (case_id,
#          cidade_destino) nos .bru de ambiente; rodar na cópia mantém
#          a árvore do repo limpa — nada de git checkout pós-run.
#
# BRUNO_ENVS: ambientes a rodar (espaço-separado). Hoje: node-container.
# R3: adicionar python-container — a paridade roda as duas suítes.
set -e

rm -rf /work
cp -r /src /work
cd /work

for env in ${BRUNO_ENVS:-node-container}; do
  echo ""
  echo "== suíte de paridade — ambiente: ${env}"
  bru run --env "${env}" -r .
done

echo ""
echo "[ok] paridade verde: ${BRUNO_ENVS:-node-container}"