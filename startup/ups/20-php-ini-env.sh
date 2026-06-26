#!/usr/bin/env bash
set -euo pipefail

PHP_SCAN_DIR=$(php --ini | while IFS= read -r line; do
    case "$line" in
        "Scan for additional .ini files in: "*)
            printf '%s\n' "${line#Scan for additional .ini files in: }"
            break
            ;;
    esac
done)

PHP_SCAN_DIR=${PHP_SCAN_DIR#\"}
PHP_SCAN_DIR=${PHP_SCAN_DIR%\"}

case "$PHP_SCAN_DIR" in
    ""|"(none)"|"No directory for additional .ini files")
        echo "Unable to determine a valid PHP scan directory from php --ini: $PHP_SCAN_DIR" >&2
        exit 1
        ;;
esac

if [ -e "$PHP_SCAN_DIR" ] && [ ! -d "$PHP_SCAN_DIR" ]; then
    echo "PHP scan path is not a directory: $PHP_SCAN_DIR" >&2
    exit 1
fi

PHP_ENV_INI="$PHP_SCAN_DIR/zz-env.ini"
PHP_ENV_VARS=$(env | while IFS='=' read -r name _; do
    case "$name" in
        PHP_INI_*)
            printf '%s\n' "$name"
            ;;
    esac
done)

if [ -z "$PHP_ENV_VARS" ]; then
    rm -f "$PHP_ENV_INI"
    exit 0
fi

mkdir -p "$PHP_SCAN_DIR"

echo "Generating PHP ini overrides from environment variables..."

{
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        key=${name#PHP_INI_}
        key=${key,,}
        key=${key//__/.}
        value=${!name}
        printf '%s = %s\n' "$key" "$value"
    done <<< "$PHP_ENV_VARS"
} > "$PHP_ENV_INI"

chmod 644 "$PHP_ENV_INI"
