FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY api-node.js .
COPY swagger/ ./swagger/

EXPOSE 3000

CMD ["node", "api-node.js"]
