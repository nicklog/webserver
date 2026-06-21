#!/usr/bin/env bash
set -euo pipefail

for script in /usr/local/bin/startup/ups/[0-4][0-9]-*.sh; do
  if [ -x "$script" ]; then
    "$script"
  fi
done

exec frankenphp run -c /etc/frankenphp/Caddyfile -w
