#!/bin/sh
set -e

# Gera o conf/system.properties a partir do template, substituindo os tokens
# @TEDROS_DB_*@ pelas variaveis de ambiente do container (feature flag do banco).
# Feito a cada start para ser idempotente em restarts do container.
sed -e "s|@TEDROS_DB_DRIVER@|${TEDROS_DB_DRIVER}|g" \
    -e "s|@TEDROS_DB_URL@|${TEDROS_DB_URL}|g" \
    -e "s|@TEDROS_DB_USER@|${TEDROS_DB_USER}|g" \
    -e "s|@TEDROS_DB_PASSWORD@|${TEDROS_DB_PASSWORD}|g" \
    "${TOMEE_HOME}/conf/system.properties.template" > "${TOMEE_HOME}/conf/system.properties"

exec "${TOMEE_HOME}/bin/catalina.sh" run
