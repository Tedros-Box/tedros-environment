FROM eclipse-temurin:17-jre-jammy

# Configurações de Ambiente
ENV TOMEE_VERSION=9.1.3
ENV TOMEE_FLAVOR=plume
ENV TOMEE_HOME=/usr/local/tomee

# Novas variáveis de ambiente para o Redis com valores fallback
ENV REDIS_HOST=localhost
ENV REDIS_PORT=6379

# Instalação de pacotes e TomEE (mantido o original)
RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*
RUN mkdir -p ${TOMEE_HOME} \
    && curl --retry 5 -fSL https://repo1.maven.org/maven2/org/apache/tomee/apache-tomee/${TOMEE_VERSION}/apache-tomee-${TOMEE_VERSION}-${TOMEE_FLAVOR}.zip -o tomee.zip \
    && unzip tomee.zip -d /usr/local \
    && mv /usr/local/apache-tomee-${TOMEE_FLAVOR}-${TOMEE_VERSION}/* ${TOMEE_HOME}/ \
    && rm tomee.zip

WORKDIR ${TOMEE_HOME}
COPY conf/* ${TOMEE_HOME}/conf/

# Cria a pasta e copia o script de inicialização do H2
RUN mkdir -p /opt/h2-data
COPY db/init.sql /opt/h2-data/init.sql

# Copia libs comuns (POI, commons, H2, etc.) para common/lib do TomEE
# Ficam disponíveis globalmente para todos os EARs/WARs deployados
RUN mkdir -p ${TOMEE_HOME}/common/lib
COPY common/lib/ ${TOMEE_HOME}/common/lib/

# --- Cópia dos artefatos de deploy ---
ARG SRC_APP=./deployment_app
ARG SRC_WEBAPP=./deployment_webapp

COPY ${SRC_APP}/ ${TOMEE_HOME}/apps/
COPY ${SRC_WEBAPP}/ ${TOMEE_HOME}/webapps/
# --------------------------------

RUN chmod +x ${TOMEE_HOME}/bin/catalina.sh
EXPOSE 8080 8081 8443 8009 8005 8000 8001
CMD ["bin/catalina.sh", "run"]