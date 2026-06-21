ARG PHP_VERSION=8.5
ARG COMPOSER_VERSION=2
ARG PNPM_VERSION=latest-11
ARG NODE_MAJOR=24
ARG UID=1000
ARG GID=1000

FROM composer/composer:${COMPOSER_VERSION}-bin AS composerbin

# ------------------------------------------------------------------------------
# Base stage: minimal runtime image for production
# ------------------------------------------------------------------------------
FROM debian:13-slim AS base

ARG PHP_VERSION
ARG UID
ARG GID

ENV DEBIAN_FRONTEND=noninteractive \
    COMPOSER_HOME="/home/app/.composer"

# Install absolute basics and repository tooling
RUN apt-get update -q && \
    apt-get upgrade -y -q && \
    apt-get install -qqy --no-install-recommends --fix-missing \
        apt-transport-https \
        ca-certificates \
        curl \
        gettext \
        gnupg \
        lsb-release \
        util-linux \
        wget

# Add package repositories (sury PHP + frankenPHP)
ADD docker/trusted/ /etc/apt/keyrings/
ADD docker/sources/php.sources /etc/apt/sources.list.d/
ADD docker/sources/frankenphp.sources.template /etc/apt/sources.list.d/
RUN chmod 644 /etc/apt/keyrings/* && \
    export FRANKENPHP_API=$(echo $PHP_VERSION | tr -d .) && \
    envsubst '$FRANKENPHP_API' \
        < /etc/apt/sources.list.d/frankenphp.sources.template \
        > /etc/apt/sources.list.d/frankenphp.sources && \
    rm /etc/apt/sources.list.d/*.sources.template

# Install runtime packages
RUN apt-get update -q && \
    apt-get install -qqy --no-install-recommends --fix-missing \
        mariadb-client \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-pdo \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-imagick \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-opcache \
        frankenphp \
        php-zts-pdo-mysql \
        php-zts-zip \
        php-zts-intl \
        php-zts-soap \
        php-zts-gd \
        php-zts-imagick \
        php-zts-bcmath

# Install OPcache explicitly for PHP versions where it is not bundled
RUN case "$PHP_VERSION" in \
        8.4|8.3|8.2|8.1|8.0) apt-get update -q && \
            apt-get install -qqy --no-install-recommends --fix-missing "php${PHP_VERSION}-opcache" ;; \
    esac

# Create application user with fixed UID/GID
RUN groupadd -g "${GID}" app && \
    useradd -m -g app --shell /usr/bin/bash -u "${UID}" app

# PHP base configuration (timezone, memory)
ADD frankenphp/php.d/custom.ini /etc/php/${PHP_VERSION}/cli/conf.d/50-custom.ini
RUN chmod 644 /etc/php/${PHP_VERSION}/cli/conf.d/50-custom.ini

# FrankenPHP / Caddy configuration
RUN mkdir -p /etc/frankenphp
ADD frankenphp/Caddyfile /etc/frankenphp/Caddyfile
ADD frankenphp/caddy.d/ /etc/frankenphp/caddy.d/

# MySQL client configuration template
ADD docker/files/.my.cnf.template /home/app/.my.cnf.template

# Startup scripts
ADD startup/startup.sh /usr/local/bin/startup/startup
ADD startup/ups/ /usr/local/bin/startup/ups/
RUN chmod +x /usr/local/bin/startup/startup /usr/local/bin/startup/ups/*.sh

# Prepare application directory
RUN mkdir -p /app/public /var/log/php && \
    chown -R app:app /home/app /app /var/log/php

ENV TERM=xterm-256color

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -sS --max-time 3 http://localhost:8000/ > /dev/null || exit 1

CMD ["/usr/local/bin/startup/startup"]

# ------------------------------------------------------------------------------
# Production stage: hardened PHP configuration
# ------------------------------------------------------------------------------
FROM base AS prod

ARG PHP_VERSION

ADD frankenphp/php.d/production.ini /etc/php/${PHP_VERSION}/cli/conf.d/60-production.ini
RUN chmod 644 /etc/php/${PHP_VERSION}/cli/conf.d/60-production.ini

USER app:app
WORKDIR /app

# ------------------------------------------------------------------------------
# Development stage: base + tooling
# ------------------------------------------------------------------------------
FROM base AS dev

ARG PHP_VERSION
ARG PNPM_VERSION
ARG NODE_MAJOR

# Add development repositories (NodeSource + gierens for eza)
ADD docker/sources/nodesource.sources.template /etc/apt/sources.list.d/
ADD docker/sources/gierens.sources /etc/apt/sources.list.d/
RUN envsubst '$NODE_MAJOR' \
        < /etc/apt/sources.list.d/nodesource.sources.template \
        > /etc/apt/sources.list.d/nodesource.sources && \
    rm /etc/apt/sources.list.d/*.sources.template

# Install development tooling
RUN apt-get update -q && \
    apt-get install -qqy --no-install-recommends --fix-missing \
        eza \
        fzf \
        git \
        htop \
        jq \
        less \
        nano \
        patch \
        pv \
        unzip \
        zsh \
        zoxide \
        nodejs \
        php-zts-pcov

# Install pnpm
RUN npm install -g pnpm@${PNPM_VERSION}

# Install Composer (development only)
COPY --link --from=composerbin /composer /usr/bin/composer

# Development PHP configuration
ADD frankenphp/php.d/development.ini /etc/php/${PHP_VERSION}/cli/conf.d/60-development.ini
RUN chmod 644 /etc/php/${PHP_VERSION}/cli/conf.d/60-development.ini

# Shell configuration
ADD zsh/ /home/app/

ENV PNPM_HOME="/home/app/.pnpm-store" \
    PATH="/home/app/.pnpm-store:$PATH"

RUN mkdir -p /home/app/.pnpm-store && \
    chown -R app:app /home/app /app && \
    su app -c "zsh -c 'source /home/app/.zshrc'" || true

USER app:app
WORKDIR /app
