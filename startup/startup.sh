#!/usr/bin/env bash
set -euo pipefail

for script in /usr/local/bin/startup/ups/*.sh; do
  if [ -x "$script" ]; then
    "$script"
  fi
done
