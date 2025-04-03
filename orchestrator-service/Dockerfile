FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

ENV NODE_ENV=production
RUN npm install --only=production

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
