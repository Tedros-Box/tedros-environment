-- Provisionamento do PostgreSQL para o Tedros
-- Executado automaticamente pelo container (montado em /docker-entrypoint-initdb.d/).
-- No PostgreSQL o usuario ja e criado pelo POSTGRES_USER; aqui criamos apenas
-- os schemas usados pelas persistence units (interfaces DomainSchema).
CREATE SCHEMA IF NOT EXISTS tedros_core    AUTHORIZATION tdrs;
CREATE SCHEMA IF NOT EXISTS tedros_apps    AUTHORIZATION tdrs;
CREATE SCHEMA IF NOT EXISTS tedros_ext     AUTHORIZATION tdrs;
CREATE SCHEMA IF NOT EXISTS tedros_common  AUTHORIZATION tdrs;
CREATE SCHEMA IF NOT EXISTS tedros_samples AUTHORIZATION tdrs;
