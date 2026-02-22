# ── Build stage ───────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app

COPY package*.json ./
# Install ALL deps (including devDeps) — needed for build tools like typescript, vite, etc.
RUN npm install --no-audit --no-fund

COPY . .
# Transpile/bundle if a build script exists, otherwise no-op
RUN npm run build --if-present

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM node:20-alpine
WORKDIR /app

# Non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy entire app from builder — works whether or not a dist/ folder was created
COPY --chown=appuser:appgroup --from=builder /app ./

USER appuser
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["npm", "start"]