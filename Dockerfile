# syntax=docker/dockerfile:1

# The build output is static files, identical for every target platform, so the
# build stage always runs on the builder's native architecture.
FROM --platform=$BUILDPLATFORM oven/bun:1 AS build
WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

COPY . .
RUN bun run build

# Keep this stage free of RUN instructions: it lets multi-platform builds
# assemble every architecture without QEMU emulation.
FROM nginxinc/nginx-unprivileged:stable-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
# The app is built with the "/dns-profile-generator/" base path (vite.config.ts).
COPY --from=build /app/dist /usr/share/nginx/html/dns-profile-generator

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget -q --spider http://127.0.0.1:8080/dns-profile-generator/ || exit 1
