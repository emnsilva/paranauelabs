# ADR-005: node:22-alpine, dependências do lockfile QUANDO presente.

# ---- build ----
    FROM node:22-alpine AS build
    WORKDIR /app
    COPY package.json package-lock.json* ./
    RUN npm install
    
    # ---- final ----
    FROM node:22-alpine
    WORKDIR /app
    ENV NODE_ENV=production
    COPY --from=build /app/node_modules ./node_modules
    COPY package.json ./
    COPY src ./src
    COPY data/seed.json /app/seed.json
    USER node
    EXPOSE 7421
    CMD ["node", "src/index.js"]