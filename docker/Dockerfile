FROM eclipse-temurin:17-jre-jammy

# Configurações de Ambiente
ENV TOMEE_VERSION=9.1.3
ENV TOMEE_FLAVOR=plume
ENV TOMEE_HOME=/usr/local/tomee

# Novas variáveis de ambiente para o Redis com valores fallback
ENV REDIS_HOST=localhost
ENV REDIS_PORT=6379

# Versão do driver JDBC do PostgreSQL incluído em common/lib
ENV POSTGRESQL_JDBC_VERSION=42.7.5

# Feature flag do banco (defaults = PostgreSQL, provider atual).
# Sobrescreva TEDROS_DB_* no compose/.env.<vendor> para outro banco.
# Drivers de outros vendors entram em common/lib da mesma forma.
ENV TEDROS_DB_DRIVER="org.postgresql.Driver"
ENV TEDROS_DB_URL="jdbc:postgresql://postgres:5432/tedros?stringtype=unspecified"
ENV TEDROS_DB_USER=tdrs
ENV TEDROS_DB_PASSWORD=xpto

# Instalação de pacotes e TomEE (mantido o original)
RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*
RUN mkdir -p ${TOMEE_HOME} \
    && curl --retry 5 -fSL https://repo1.maven.org/maven2/org/apache/tomee/apache-tomee/${TOMEE_VERSION}/apache-tomee-${TOMEE_VERSION}-${TOMEE_FLAVOR}.zip -o tomee.zip \
    && unzip tomee.zip -d /usr/local \
    && mv /usr/local/apache-tomee-${TOMEE_FLAVOR}-${TOMEE_VERSION}/* ${TOMEE_HOME}/ \
    && rm tomee.zip

WORKDIR ${TOMEE_HOME}
COPY conf/* ${TOMEE_HOME}/conf/

# O system.properties vira template: o entrypoint.sh gera o arquivo final
# a cada start substituindo os tokens @TEDROS_DB_*@ pelas env vars
RUN mv ${TOMEE_HOME}/conf/system.properties ${TOMEE_HOME}/conf/system.properties.template

# Copia libs comuns (POI, commons, etc.) para common/lib do TomEE
# Ficam disponíveis globalmente para todos os EARs/WARs deployados
RUN mkdir -p ${TOMEE_HOME}/common/lib
COPY common/lib/ ${TOMEE_HOME}/common/lib/

# Driver JDBC do PostgreSQL em common/lib — o driver pertence ao container,
# não à aplicação. Outros vendors: adicionar o JAR da mesma forma.
RUN curl --retry 5 -fSL https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRESQL_JDBC_VERSION}/postgresql-${POSTGRESQL_JDBC_VERSION}.jar \
    -o ${TOMEE_HOME}/common/lib/postgresql-${POSTGRESQL_JDBC_VERSION}.jar

# --- Cópia dos artefatos de deploy ---
ARG SRC_APP=./deployment_app
ARG SRC_WEBAPP=./deployment_webapp

COPY ${SRC_APP}/ ${TOMEE_HOME}/apps/
COPY ${SRC_WEBAPP}/ ${TOMEE_HOME}/webapps/
# --------------------------------

COPY entrypoint.sh /entrypoint.sh
# Remove CRLF (repo em Windows) e garante permissão de execução
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

RUN chmod +x ${TOMEE_HOME}/bin/catalina.sh
EXPOSE 8080 8081 8443 8009 8005 8000 8001
CMD ["/entrypoint.sh"]
