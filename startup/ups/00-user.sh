#!/usr/bin/env bash
set -euo pipefail

APP_UID=${UID:-1000}
APP_GID=${GID:-1000}

CURRENT_UID=$(id -u app)
CURRENT_GID=$(id -g app)

if [ "$CURRENT_UID" != "$APP_UID" ] || [ "$CURRENT_GID" != "$APP_GID" ]; then
    echo "Updating app user: UID=$APP_UID, GID=$APP_GID"

    groupmod -g "$APP_GID" app
    usermod -u "$APP_UID" app
    chown -R app:app /home/app /app /var/log/php
fi
