ARG PHP_VERSION=8.4
ARG COMPOSER_VERSION=2

FROM dunglas/frankenphp:1-php${PHP_VERSION} AS frankenphp
FROM composer/composer:${COMPOSER_VERSION}-bin  AS composerbin

FROM debian:trixie-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG UID=1000
ARG GID=1000
ARG PHP_VERSION

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
    libcap2-bin \
    pv \
    less \
    nano \
    unzip \
    msmtp \
    msmtp-mta \
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
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-imagick \
    php${PHP_VERSION}-bcmath

# install nodejs
RUN apt install -qqy --no-install-recommends --fix-missing \
    nodejs

# install pnpm
RUN npm install -g pnpm

# copy the Composer PHAR from the Composer image into the PHP image
COPY --link --from=composerbin /composer /usr/bin/composer

COPY --link --from=frankenphp /usr/local/lib/libwatcher* /usr/local/lib/
COPY --link --from=frankenphp /usr/local/lib/libphp.so* /usr/local/lib/
COPY --link --from=frankenphp /usr/local/bin/frankenphp /usr/local/bin/

RUN ldconfig /usr/local/lib
RUN setcap cap_net_bind_service=+ep /usr/local/bin/frankenphp

# add app user
RUN groupadd -g "${GID}" app && \
	useradd -m -g app --shell /usr/bin/zsh -u "${UID}" app

# configure php-fpm
ADD frankenphp/php.d/custom.ini /etc/php/${PHP_VERSION}/cli/conf.d/50-custom.ini

RUN mkdir -p /etc/frankenphp
ADD frankenphp/ /etc/frankenphp

# configure msmtp
ADD docker/files/msmtprc /etc/msmtprc

# zsh
ADD zsh/ /home/app/

# link mysql config
ADD docker/files/.my.cnf.template /home/app/.my.cnf.template

# startup script
ADD startup/ups/ /usr/local/bin/startup/
ADD startup/startup.sh /usr/local/bin/startup
RUN chmod +x /usr/local/bin/startup
RUN chmod +x /usr/local/bin/startup/*.sh

ENV TERM=xterm-256color
ENV COLORTERM=truecolor
ENV PNPM_HOME=/home/app/.pnpm-store

RUN mkdir -p /app/public
RUN chown -R app:app /home/app /app

# expose ports
EXPOSE 80

# start services
CMD ["/usr/local/bin/startup.sh"]

USER app:app
WORKDIR /app
