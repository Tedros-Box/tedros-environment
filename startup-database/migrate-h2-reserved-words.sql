-- ============================================================
-- Migracao unica para bases H2 EXISTENTES (criadas antes do
-- suporte a PostgreSQL): renomeia identificadores que eram
-- palavras reservadas no PostgreSQL.
--
--   coluna  TO    -> send_to    (tedros_core.notify)
--   coluna  USER  -> user_name  (tedros_core.ai_*)
--   tabela  user  -> users      (tedros_core)
--   tabela  binary-> binary_data(tedros_common)
--
-- Como executar (uma unica vez por base):
--   1. Suba o H2 (startup-database) e abra o console web
--   2. Conecte na base do Tedros (usuario tdrs)
--   3. Execute este script
--
-- Bases novas (H2 ou PostgreSQL) NAO precisam disto: o EclipseLink
-- ja cria tudo com os nomes novos.
-- ============================================================

ALTER TABLE IF EXISTS tedros_core.notify ALTER COLUMN "TO" RENAME TO send_to;
ALTER TABLE IF EXISTS tedros_core.ai_completion ALTER COLUMN "USER" RENAME TO user_name;
ALTER TABLE IF EXISTS tedros_core.ai_create_image ALTER COLUMN "USER" RENAME TO user_name;
ALTER TABLE IF EXISTS tedros_core.ai_chat_completion ALTER COLUMN "USER" RENAME TO user_name;
ALTER TABLE IF EXISTS tedros_core."USER" RENAME TO users;
ALTER TABLE IF EXISTS tedros_common."BINARY" RENAME TO binary_data;
