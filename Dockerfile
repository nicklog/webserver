ARG PHP_VERSION=8.5
ARG COMPOSER_VERSION=2
ARG PNPM_VERSION=latest-10
ARG NODE_MAJOR=24

FROM composer/composer:${COMPOSER_VERSION}-bin  AS composerbin

FROM debian:trixie-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG UID=1000
ARG GID=1000
ARG PHP_VERSION
ARG PNPM_VERSION
ARG NODE_MAJOR

ENV COMPOSER_HOME="/home/app/.composer"
ENV PNPM_HOME="/home/app/.pnpm-store"

# install absolute basics
RUN apt update -q && \
    apt upgrade -y -q && \
    apt install -qqy --no-install-recommends --fix-missing \
        curl \
        wget \
        gnupg \
        apt-transport-https \
        lsb-release \
        ca-certificates \
        gettext

# install repositories
ADD docker/trusted/ /etc/apt/keyrings/
ADD docker/sources/ /etc/apt/sources.list.d/
RUN chmod 644 /etc/apt/keyrings/*
RUN export FRANKENPHP_API=$(echo $PHP_VERSION | tr -d .) && \
    envsubst '$FRANKENPHP_API' \
        < /etc/apt/sources.list.d/frankenphp.sources.template \
        > /etc/apt/sources.list.d/frankenphp.sources && \
    envsubst '$NODE_MAJOR' \
        < /etc/apt/sources.list.d/nodesource.sources.template \
        > /etc/apt/sources.list.d/nodesource.sources && \
    rm /etc/apt/sources.list.d/*.sources.template

RUN apt update -q && \
    apt install -qqy --no-install-recommends --fix-missing \
    pv \
    less \
    nano \
    unzip \
    patch \
    git \
    jq \
    htop \
    mariadb-client \
    eza \
    zsh \
    fzf \
    zoxide \
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
    frankenphp \
    php-zts-pdo-mysql \
    php-zts-zip \
    php-zts-intl \
    php-zts-soap \
    php-zts-gd \
    php-zts-imagick \
    php-zts-bcmath \
    php-zts-pcov \
    nodejs

# install pnpm
RUN npm install -g pnpm@${PNPM_VERSION}

# copy the Composer PHAR from the Composer image into the PHP image
COPY --link --from=composerbin /composer /usr/bin/composer

# add app user
RUN groupadd -g "${GID}" app && \
	useradd -m -g app --shell /usr/bin/zsh -u "${UID}" app

# configure php-fpm
ADD frankenphp/php.d/custom.ini /etc/php/${PHP_VERSION}/cli/conf.d/50-custom.ini

RUN mkdir -p /etc/frankenphp
ADD frankenphp/ /etc/frankenphp

# zsh
ADD zsh/ /home/app/

# link mysql config
ADD docker/files/.my.cnf.template /home/app/.my.cnf.template

# startup script
ADD startup/ups/ /usr/local/bin/startup/ups
ADD startup/startup.sh /usr/local/bin/startup/startup
RUN chmod +x /usr/local/bin/startup/startup
RUN chmod +x /usr/local/bin/startup/ups/*.sh

ENV TERM=xterm-256color
ENV COLORTERM=truecolor
ENV PNPM_HOME=/home/app/.pnpm-store

RUN mkdir -p /app/public
RUN chown -R app:app /home/app /app

# load zsh plugins
RUN su app -c "zsh -c 'source /home/app/.zshrc'"

# start services
CMD ["/usr/local/bin/startup/startup"]

USER app:app
WORKDIR /app
