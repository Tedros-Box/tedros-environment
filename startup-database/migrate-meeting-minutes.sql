-- =============================================================================
-- Migração: Ata de Reunião (MeetingMinutes) — alterações de entidades
-- Database: tedros
-- Schema:   tedros_apps
--
-- Uso (Postgres / pgvector):
--   docker exec -i tedros-postgres psql -U tdrs -d tedros -f - < migrate-meeting-minutes.sql
--   ou no DBeaver: execute este script no database tedros
--
-- Idempotente: pode rodar mais de uma vez (IF NOT EXISTS / DO blocks).
-- =============================================================================

-- 1) Texto da transcrição (fonte do RAG) — campo MeetingMinutes.transcription
ALTER TABLE tedros_apps.it_meeting_minutes
	ADD COLUMN IF NOT EXISTS transcription TEXT;

-- 2) OPTLOCK (TVersionEntity) — necessário se a base foi criada antes da
--    troca de TEntity → TVersionEntity. Ambientes já migrados ignoram.
ALTER TABLE tedros_apps.it_meeting_minutes
	ADD COLUMN IF NOT EXISTS optlock INTEGER;

ALTER TABLE tedros_apps.it_meeting_agenda
	ADD COLUMN IF NOT EXISTS optlock INTEGER;

ALTER TABLE tedros_apps.it_meeting_referral
	ADD COLUMN IF NOT EXISTS optlock INTEGER;

ALTER TABLE tedros_apps.it_meeting_evidence
	ADD COLUMN IF NOT EXISTS optlock INTEGER;

-- 3) FK pai nos filhos (mappedBy) — só cria se a coluna ainda não existir
--    (bases antigas com @JoinColumn unidirecional já possuem id_meeting_minutes).
DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM information_schema.columns
		WHERE table_schema = 'tedros_apps'
		  AND table_name = 'it_meeting_agenda'
		  AND column_name = 'id_meeting_minutes'
	) THEN
		ALTER TABLE tedros_apps.it_meeting_agenda
			ADD COLUMN id_meeting_minutes BIGINT NOT NULL;
	END IF;

	IF NOT EXISTS (
		SELECT 1 FROM information_schema.columns
		WHERE table_schema = 'tedros_apps'
		  AND table_name = 'it_meeting_referral'
		  AND column_name = 'id_meeting_minutes'
	) THEN
		ALTER TABLE tedros_apps.it_meeting_referral
			ADD COLUMN id_meeting_minutes BIGINT NOT NULL;
	END IF;

	IF NOT EXISTS (
		SELECT 1 FROM information_schema.columns
		WHERE table_schema = 'tedros_apps'
		  AND table_name = 'it_meeting_evidence'
		  AND column_name = 'id_meeting_minutes'
	) THEN
		ALTER TABLE tedros_apps.it_meeting_evidence
			ADD COLUMN id_meeting_minutes BIGINT NOT NULL;
	END IF;
END $$;

-- 4) Constraints FK (só se ainda não existirem)
DO $$
BEGIN
	IF NOT EXISTS (
		SELECT 1 FROM pg_constraint WHERE conname = 'fk_it_meeting_agenda_id_meeting_minutes'
	) THEN
		ALTER TABLE tedros_apps.it_meeting_agenda
			ADD CONSTRAINT fk_it_meeting_agenda_id_meeting_minutes
			FOREIGN KEY (id_meeting_minutes) REFERENCES tedros_apps.it_meeting_minutes (id);
	END IF;

	IF NOT EXISTS (
		SELECT 1 FROM pg_constraint WHERE conname = 'fk_it_meeting_referral_id_meeting_minutes'
	) THEN
		ALTER TABLE tedros_apps.it_meeting_referral
			ADD CONSTRAINT fk_it_meeting_referral_id_meeting_minutes
			FOREIGN KEY (id_meeting_minutes) REFERENCES tedros_apps.it_meeting_minutes (id);
	END IF;

	IF NOT EXISTS (
		SELECT 1 FROM pg_constraint WHERE conname = 'fk_it_meeting_evidence_id_meeting_minutes'
	) THEN
		ALTER TABLE tedros_apps.it_meeting_evidence
			ADD CONSTRAINT fk_it_meeting_evidence_id_meeting_minutes
			FOREIGN KEY (id_meeting_minutes) REFERENCES tedros_apps.it_meeting_minutes (id);
	END IF;
END $$;

-- 5) Tabela de embeddings RAG (se o init-postgres ainda não tiver sido aplicado)
CREATE TABLE IF NOT EXISTS tedros_core.meeting_minutes_embeddings (
	embedding_id UUID PRIMARY KEY,
	embedding vector(1536),
	text TEXT NULL,
	metadata JSON NULL
);

-- Verificação rápida
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'tedros_apps'
  AND table_name = 'it_meeting_minutes'
  AND column_name IN ('transcription', 'optlock')
ORDER BY column_name;
