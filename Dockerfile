FROM debian:trixie-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG UID=1000
ARG GID=1000

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

# add trusted keys
ADD docker/trusted/ /etc/apt/keyrings/
RUN chmod 644 /etc/apt/keyrings/*

# install repositories
ADD docker/sources/ /etc/apt/sources.list.d/
RUN apt update -q

# install base packages
RUN apt install -qqy --no-install-recommends --fix-missing \
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
    php8.4-cli \
    php8.4-mbstring \
    php8.4-mysql \
    php8.4-curl \
    php8.4-xml \
    php8.4-zip \
    php8.4-pdo \
    php8.4-intl \
    php8.4-soap \
    php8.4-gd \
    php8.4-opcache \
    php8.4-imagick \
    php8.4-bcmath

# install nodejs
RUN apt install -qqy --no-install-recommends --fix-missing \
    nodejs

# install pnpm
RUN npm install -g pnpm

# copy the Composer PHAR from the Composer image into the PHP image
COPY --from=composer/composer:2-bin /composer /usr/bin/composer

# copy frankenphp
RUN curl https://frankenphp.dev/install.sh | sh && \
    mv frankenphp /usr/local/bin/

# add app user
RUN groupadd -g "${GID}" app && \
	useradd -m -g app --shell /usr/bin/zsh -u "${UID}" app

# configure php-fpm
RUN mkdir -p /run/php
ADD frankenphp/php.d/custom.ini /etc/php/8.4/cli/conf.d/50-custom.ini

RUN mkdir -p /run/frankenphp
ADD frankenphp/ /etc/frankenphp

# configure msmtp
ADD docker/files/msmtprc /etc/msmtprc

# zsh
ADD zsh/ /home/app/

# link mysql config
ADD docker/files/.my.cnf.template /home/app/.my.cnf.template

# startup script
ADD startup/ /usr/local/bin/startup/
RUN chmod +x /usr/local/bin/startup/*.sh

ENV TERM=xterm-256color
ENV COLORTERM=truecolor
ENV PNPM_HOME=/home/app/.pnpm-store

RUN mkdir -p /app/public
RUN chown -R app:app /home/app /app

# expose ports
EXPOSE 80
EXPOSE 9999

# start services
CMD ["/bin/bash", "-c", "for script in /usr/local/bin/startup/*.sh; do [ -x \"$script\" ] && \"$script\"; done"]

USER app:app
WORKDIR /app
