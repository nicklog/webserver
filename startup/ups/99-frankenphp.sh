#!/usr/bin/env bash

echo "Starte FrankenPHP..."
exec setpriv --reuid="$(id -u app)" --regid="$(id -g app)" --init-groups frankenphp run -c /etc/frankenphp/Caddyfile -w
