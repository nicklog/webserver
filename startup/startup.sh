#!/usr/bin/env bash
set -euo pipefail

# Run all setup hooks (numbered 00-49)
for script in /usr/local/bin/startup/ups/[0-4][0-9]-*.sh; do
  if [ -x "$script" ]; then
    "$script"
  fi
done

exec frankenphp start -c /etc/frankenphp/Caddyfile -w
