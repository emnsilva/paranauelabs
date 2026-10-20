# Runner da suíte de paridade — Bruno CLI pré-instalado e pinado no build.
# (npx baixaria o CLI a cada execução: mais lento e versão flutuante)
FROM node:22-alpine

# Versão vem de .env (BRUNO_CLI_VERSION) via compose build args —
# a mesma linha que passou 28/28 na aceitação R2.9.
# Sem default: se faltar, o build falha ALTO (nunca roda "latest" mudo).
ARG BRUNO_VERSION
RUN npm install -g @usebruno/cli@${BRUNO_VERSION} --no-fund --no-audit

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]