# Build stage
FROM node:18-alpine AS builder

# Install system dependencies for native modules
RUN apk add --no-cache git python3 make g++

# Install pnpm
RUN npm install -g pnpm

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml* ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build arguments for Next.js public variables
ARG NEXT_PUBLIC_BASE_URL
ARG NEXT_PUBLIC_STORAGE_URL
ARG NEXT_PUBLIC_AVATAR_BUCKET_NAME
ARG NEXT_PUBLIC_ALLOW_CREDENTIALS
ARG NEXT_PUBLIC_DISABLE_SIGN_UP

# Build the application
RUN pnpm build

# Production stage
FROM node:18-alpine AS runner

WORKDIR /app

# Copy built assets from builder
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/pnpm-lock.yaml ./pnpm-lock.yaml

# Install production dependencies
RUN npm install -g pnpm && \
    pnpm install --prod --frozen-lockfile

# Expose the port
EXPOSE 3000

# Start the application
CMD ["pnpm", "start"]
