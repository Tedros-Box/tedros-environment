FROM mongo:8.2.5

# mongo:8.2.5 é baseado nativamente no Ubuntu 24.04 LTS
ENV DEBIAN_FRONTEND=noninteractive

# Atualizando repositórios e instalando o NGINX
RUN apt-get update && \
    apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/*

# Copia script de inicialização unificado
COPY start-services.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-services.sh

EXPOSE 80 27017

# Define nosso script como processo raiz
ENTRYPOINT ["/usr/local/bin/start-services.sh"]
