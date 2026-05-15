# Stage 1: Build
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
# Make package-lock.json optional using * so it doesn't fail if missing
COPY package.json package-lock.json* ./

# Install dependencies
# Use npm install instead of npm ci to handle lock file sync issues
RUN npm install --production=false

# Copy source code
COPY . .

# Build the React app
RUN npm run build

# Stage 2: Runtime
FROM node:18-alpine

WORKDIR /app

# Install serve to run the production build
RUN npm install -g serve

# Copy built app from builder stage
COPY --from=builder /app/build ./build

# Expose port
EXPOSE 3000

# Set environment variable for API URL (can be overridden at runtime)
ENV REACT_APP_API_URL=http://localhost:5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start the app
CMD ["serve", "-s", "build", "-l", "3000"]
