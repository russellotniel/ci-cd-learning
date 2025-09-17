# Multi-stage build for Next.js
FROM node:22-alpine AS base

# Install dependencies only when needed
FROM base AS deps
# libc6-compat for Alpine compatibility with node-gyp
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy package files ONLY (for better caching)
COPY package*.json ./
# Install dependencies based on lockfile
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i; \
  else echo "Lockfile not found." && exit 1; \
  fi

# Rebuild the source code only when needed
FROM base AS builder
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy installed dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
# Now copy all source code
COPY . .

# Build the application
RUN npm run build

# Ensure public directory exists
RUN mkdir -p /app/public || true

# Production image, copy all files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

# Create nodejs group and nextjs user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy public folder (if it exists)
COPY --from=builder /app/public ./public

# Copy standalone build
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000
ENV PORT 3000

# Use HOSTNAME=0.0.0.0 for proper container networking
CMD ["sh", "-c", "HOSTNAME=0.0.0.0 node server.js"]