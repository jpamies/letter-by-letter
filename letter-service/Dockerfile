FROM node:18-alpine

# Install dependencies required for canvas
RUN apk add --no-cache \
    build-base \
    g++ \
    cairo-dev \
    jpeg-dev \
    pango-dev \
    giflib-dev \
    python3 \
    py3-pip \
    font-noto \
    font-noto-cjk \
    font-noto-extra

WORKDIR /app

COPY package*.json ./

ENV NODE_ENV=production
RUN npm i --cpu arm64 --only=production

COPY . .

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
