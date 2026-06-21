#!/usr/bin/env bash

# Generate .my.cnf only when all required variables are set
if [ -n "$MYSQL_HOST" ] && [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_PASSWORD" ] && [ -n "$MYSQL_DATABASE" ]; then
	echo "Generating .my.cnf from environment variables..."

	envsubst < /home/app/.my.cnf.template > /home/app/.my.cnf
	chmod 600 /home/app/.my.cnf
else
	echo "Not all MySQL environment variables are set; skipping .my.cnf generation"
fi
