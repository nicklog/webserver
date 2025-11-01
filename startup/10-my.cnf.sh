#!/usr/bin/env bash

# Generiere .my.cnf nur wenn Umgebungsvariablen gesetzt sind
if [ -n "$MYSQL_HOST" ] || [ -n "$MYSQL_USER" ] || [ -n "$MYSQL_PASSWORD" ] || [ -n "$MYSQL_DATABASE" ]; then
	echo "Generiere .my.cnf aus Umgebungsvariablen..."

	envsubst < /home/app/.my.cnf.template > /home/app/.my.cnf
	chmod 600 /home/app/.my.cnf
else
	echo "Keine MySQL Umgebungsvariablen gesetzt, verwende Standard .my.cnf"
fi
