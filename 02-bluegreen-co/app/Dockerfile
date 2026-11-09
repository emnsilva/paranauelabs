# Estágio 1: Builder (Compilação)
FROM python:3.12-alpine3.24 AS builder

WORKDIR /app

# Instala dependências de compilação (necessárias para o psycopg2 no Alpine)
RUN apk add --no-cache gcc musl-dev postgresql-dev

# Cria um ambiente virtual e instala as dependências
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Estágio 2: Runner (Execução)
FROM python:3.12-alpine3.24

WORKDIR /app

# Instala apenas a biblioteca de runtime do PostgreSQL (sem compiladores)
RUN apk add --no-cache libpq

# Copia o ambiente virtual criado no estágio 1
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Cria um usuário não-root para segurança
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Copia o código da aplicação
COPY --chown=appuser:appgroup bgapp/ ./bgapp/

# Expõe a porta do Gunicorn
EXPOSE 5000

# Comando para rodar a aplicação em produção
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "bgapp:create_app()"]