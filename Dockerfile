# ── Build stage ──────────────────────────────────────
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# ── Production stage ─────────────────────────────────
FROM node:20-alpine AS production

RUN apk add --no-cache dumb-init

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY --from=build /app/dist ./dist

# Non-root user
RUN addgroup -g 1001 -S staynest && \
    adduser -S staynest -u 1001 -G staynest
USER staynest

EXPOSE 3000

# Graceful shutdown
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/main"]
