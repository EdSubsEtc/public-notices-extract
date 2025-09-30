FROM node:22-bookworm-slim AS base
WORKDIR /app

COPY *.js package.json package-lock.json ./
COPY sql/ ./sql/

RUN npm ci --omit=dev


# The command to run the application.
CMD [ "npm", "run", "cloudRun" ]