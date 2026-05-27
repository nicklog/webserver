ARG PHP_VERSION=8.5
ARG COMPOSER_VERSION=2
ARG PNPM_VERSION=latest-10

FROM composer/composer:${COMPOSER_VERSION}-bin  AS composerbin

FROM debian:trixie-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG UID=1000
ARG GID=1000
ARG PHP_VERSION
ARG PNPM_VERSION

# install absolute basics
RUN apt update -q && \
    apt upgrade -y -q && \
    apt install -qqy --no-install-recommends --fix-missing \
        curl \
        wget \
        gnupg \
        apt-transport-https \
        lsb-release \
        ca-certificates

# install repositories
ADD docker/trusted/ /etc/apt/keyrings/
ADD docker/sources/ /etc/apt/sources.list.d/
RUN chmod 644 /etc/apt/keyrings/*
RUN apt update -q

# install base packages
RUN apt install -qqy --no-install-recommends --fix-missing \
    pv \
    less \
    nano \
    unzip \
    patch \
    git \
    jq \
    htop \
	gettext

# mariadb
RUN apt install -qqy --no-install-recommends --fix-missing \
    mariadb-client

# for zsh
RUN apt install -qqy --no-install-recommends --fix-missing \
    eza \
    zsh \
    fzf \
    zoxide

# install php
RUN apt install -qqy --no-install-recommends --fix-missing \
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
    php${PHP_VERSION}-bcmath

# install frankenphp
RUN apt install -qqy --no-install-recommends --fix-missing \
    frankenphp

# install nodejs
RUN apt install -qqy --no-install-recommends --fix-missing \
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

# expose ports
EXPOSE 8000

# start services
CMD ["/usr/local/bin/startup/startup"]

USER app:app
WORKDIR /app
