# ---- Build stage ----
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files and install deps (cached layer)
COPY package*.json ./
RUN npm ci --only=production

# ---- Runtime stage ----
FROM node:20-alpine

WORKDIR /app

# Create a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only production deps from builder
COPY --from=builder /app/node_modules ./node_modules
COPY . .

# Drop root privileges
USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "index.js"]
