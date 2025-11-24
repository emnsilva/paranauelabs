FROM node:18-alpine
WORKDIR /app

# Copia tudo da pasta APIs
COPY APIs/ ./

RUN npm install

EXPOSE 3000
CMD ["node", "api-node.js"]