#!/usr/bin/env bash
set -euo pipefail

# Run all setup hooks (numbered 00-49) as root
for script in /usr/local/bin/startup/ups/[0-4][0-9]-*.sh; do
  if [ -x "$script" ]; then
    "$script"
  fi
done

# Start FrankenPHP as PID 1 under the app user
exec setpriv --reuid=app --regid=app --clear-groups \
    frankenphp start -c /etc/frankenphp/Caddyfile -w
