# syntax = docker/dockerfile:1

ARG NODE_VERSION=22.21.1
FROM node:${NODE_VERSION}-slim AS base

LABEL fly_launch_runtime="Node.js"

WORKDIR /app

ENV NODE_ENV="production"

# 👇 fix: CI mode enable (important)
ENV CI=true

ARG PNPM_VERSION=latest
RUN npm install -g pnpm@$PNPM_VERSION


# ---------- Build Stage ----------
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential node-gyp pkg-config python-is-python3

COPY .npmrc package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod=false

COPY . .

RUN pnpm run build

# 👇 এখন এটা আর crash করবে না
RUN pnpm prune --prod


# ---------- Final Stage ----------
FROM base

COPY --from=build /app /app

EXPOSE 3000

CMD [ "pnpm", "run", "start" ]