FROM node:18-alpine

WORKDIR /app

COPY APIs/package*.json ./
RUN npm install

COPY APIs/api-node.js .
COPY ../swagger/ ./swagger/

EXPOSE 3000

CMD ["node", "api-node.js"]