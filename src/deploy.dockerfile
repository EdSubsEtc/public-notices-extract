FROM node:22-bookworm-slim AS base
WORKDIR /app

COPY *.js package.json package-lock.json ./
RUN npm ci --omit=dev

# Expose the port the app runs on.
EXPOSE 8080

# The command to run the application.
CMD [ "npm", "run", "cloudRun" ]