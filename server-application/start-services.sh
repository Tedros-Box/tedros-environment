#!/bin/bash
set -e

# Inicia o Nginx em background
echo "Iniciando NGINX..."
nginx -g "daemon off;" &

# Transfere a execução para o script oficial do MongoDB
# Isso garante que as variáveis de ambiente de init do Mongo (ex: criação de ROOT) funcionem
echo "Iniciando MongoDB..."
exec /usr/local/bin/docker-entrypoint.sh mongod --bind_ip_all
