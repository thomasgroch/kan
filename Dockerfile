# Build stage
FROM node:20-alpine AS builder

# Install system dependencies for native modules
RUN apk add --no-cache git python3 make g++

# Install pnpm and dotenv-cli
RUN npm install -g pnpm dotenv-cli

WORKDIR /app

# Copy workspace configuration
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# Create directory structure and copy package.json files
COPY apps/ ./apps/
COPY packages/ ./packages/
COPY tooling/ ./tooling/

# Install all dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build arguments for Next.js public variables
ARG NEXT_PUBLIC_BASE_URL
ARG NEXT_PUBLIC_STORAGE_URL
ARG NEXT_PUBLIC_AVATAR_BUCKET_NAME
ARG NEXT_PUBLIC_ALLOW_CREDENTIALS
ARG NEXT_PUBLIC_DISABLE_SIGN_UP

# Set environment variables for build
ENV BETTER_AUTH_SECRET="dummy-secret-for-build"
ENV POSTGRES_URL="postgresql://dummy:dummy@localhost:5432/dummy"
ENV NEXT_PUBLIC_BASE_URL="https://localhost:3000"

# Build the application
RUN pnpm build

# Production stage
FROM node:20-alpine AS runner

WORKDIR /app

# Copy the entire built workspace from builder
COPY --from=builder /app ./

# Install pnpm and dotenv-cli
RUN npm install -g pnpm dotenv-cli

# Expose the port
EXPOSE 3000

# Start the web application
CMD ["pnpm", "--filter", "@kan/web", "start"]
