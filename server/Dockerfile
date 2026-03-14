FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

FROM node:20-alpine AS runtime
RUN addgroup -g 1001 -S nodejs && adduser -S tavla -u 1001
WORKDIR /app
COPY --from=deps --chown=tavla:nodejs /app/node_modules ./node_modules
COPY --chown=tavla:nodejs . .
USER tavla
EXPOSE 3000
CMD ["node", "src/index.js"]
