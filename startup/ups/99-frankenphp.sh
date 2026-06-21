#!/usr/bin/env bash

echo "Starte FrankenPHP..."
exec frankenphp run -c /etc/frankenphp/Caddyfile -w
