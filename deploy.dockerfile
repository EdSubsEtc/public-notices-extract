# Use a Node.js image as a base.
FROM node:22-bookworm-slim AS base
WORKDIR /usr/src/app

# ---- Dependencies Stage ----
# Install production dependencies.
FROM base AS dependencies
COPY package.json package-lock.json ./
RUN npm ci --omit=dev



