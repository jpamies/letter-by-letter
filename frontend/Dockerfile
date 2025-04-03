FROM node:18-alpine as build

WORKDIR /app

COPY package*.json ./

ENV NODE_ENV=production
RUN npm install

COPY . .

# Build the production version of the app
RUN npm run build

# Production environment
FROM nginx:alpine

# Copy built assets from the build stage
COPY --from=build /app/build /usr/share/nginx/html

# Add nginx configuration to handle React Router
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]
