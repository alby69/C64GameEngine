# syntax=docker/dockerfile:1
#
# C64GameEngine - Production image
# Multi-stage build: Node (Vite build) -> Nginx (static SPA server)

############################################
# 1) BUILD STAGE
############################################
FROM node:22-alpine AS builder

WORKDIR /app

# Install dependencies first so that the layer is cached
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

# Only the files needed for the compilation
COPY tsconfig.json vite.config.js index.html ./
COPY src ./src
# The web app shows the real Assembly sources (imported with Vite `?raw`)
COPY engine ./engine
COPY games ./games

RUN npm run build

############################################
# 2) RUNTIME STAGE
############################################
FROM nginx:alpine AS runtime

LABEL org.opencontainers.image.title="C64GameEngine" \
      org.opencontainers.image.description="C64 Assembly Game Engine - React/Vite frontend" \
      org.opencontainers.image.source="https://github.com/alby69/c64-space-invaders"

ENV TZ=Europe/Rome \
    NGINX_PORT=80

# Custom nginx configuration (SPA fallback + gzip + cache headers)
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf

# Compiled static assets
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
