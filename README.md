# webserver

FrankenPHP-based base image for PHP applications. Built for production use behind a reverse proxy, with a separate development target for local debugging.

## Image variants

Images are published to `ghcr.io/<owner>/webserver`.

### Production (`target: prod`)

Minimal runtime image: FrankenPHP, PHP extensions, MariaDB client. No Node.js, no shell tooling, no Composer.

| Tag | Description |
|-----|-------------|
| `latest` | PHP 8.5 production image |
| `php8.5` | PHP 8.5 production image |
| `php8.4` | PHP 8.4 production image |

### Development (`target: dev`)

Production image plus development tooling: Node.js, pnpm, Composer, Zsh, Git, MariaDB client, etc. Tags carry a `-dev` suffix.

| Tag | Description |
|-----|-------------|
| `latest-dev` | PHP 8.5 / Node 26 / pnpm 11 development image |
| `php8.5-dev` | PHP 8.5 development image |
| `php8.5-node26-pnpm11-dev` | Specific combination |

## Local development

Copy the example environment file and start the container:

```bash
cp .env.example .env
# edit .env if needed
docker compose up --build
```

The Compose file builds the `dev` target and mounts the project directory into `/app`.

## Building manually

```bash
# Production image
docker build --target prod --build-arg PHP_VERSION=8.5 -t webserver:prod .

# Development image
docker build --target dev --build-arg PHP_VERSION=8.5 --build-arg NODE_MAJOR=26 --build-arg PNPM_VERSION=10.2.1 -t webserver:dev .
```

## Security notes

- The container listens on `:8000` with `auto_https off`. It is designed to run behind a reverse proxy that terminates TLS.
- The production image disables `display_errors`, `expose_php`, `allow_url_fopen`, and assertions.
- Sensitive files (`.env`, `.git`, `composer.*`, `vendor/`, `node_modules/`, logs) are blocked at the Caddy level.
- Security headers (`X-Frame-Options`, `X-Content-Type-Options`, etc.) are set by default. HSTS is intentionally left to the TLS-terminating reverse proxy.
- Composer is intentionally only available in the `dev` image.
- Do not commit real credentials. Use `.env` locally and inject secrets via your orchestrator in production.

## Dockerfile targets

| Stage | Purpose |
|-------|---------|
| `composerbin` | Extracts the Composer PHAR (dev only) |
| `base` | Minimal runtime with FrankenPHP, PHP, MariaDB client |
| `prod` | Hardened production image |
| `dev` | Development image with tooling |
