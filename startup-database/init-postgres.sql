-- Provisionamento do PostgreSQL para o Tedros (ambiente local)
-- Executado automaticamente pelo container na primeira inicializacao
-- (montado em /docker-entrypoint-initdb.d/ pelo docker-compose-pg.yml).
-- No PostgreSQL o usuario ja e criado pelo POSTGRES_USER; aqui criamos apenas
-- os schemas usados pelas persistence units (interfaces DomainSchema).
CREATE EXTENSION IF NOT EXISTS vector;
CREATE SCHEMA IF NOT EXISTS tedros_core    AUTHORIZATION tdrs;
CREATE SCHEMA IF NOT EXISTS tedros_apps    AUTHORIZATION tdrs;
CREATE SCHEMA IF NOT EXISTS tedros_ext     AUTHORIZATION tdrs;
CREATE SCHEMA IF NOT EXISTS tedros_common  AUTHORIZATION tdrs;
CREATE SCHEMA IF NOT EXISTS tedros_samples AUTHORIZATION tdrs;

-- RAG: embeddings de atas (LangChain4j PgVectorEmbeddingStore + text-embedding-3-small = 1536)
CREATE TABLE IF NOT EXISTS tedros_core.meeting_minutes_embeddings (
	embedding_id UUID PRIMARY KEY,
	embedding vector(1536),
	text TEXT NULL,
	metadata JSON NULL
);
