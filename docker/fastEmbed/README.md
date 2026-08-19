# FastEmbed + pgvector (POC PT-BR)

POC local para ingerir atas/transcrições e documentos em português, gerar embeddings com **FastEmbed** (ONNX/CPU) e buscar por similaridade com **PostgreSQL + pgvector**.

## Viabilidade na sua máquina

| Recurso | Sua config | Necessário (POC) | Status |
|---------|------------|------------------|--------|
| CPU | Ryzen 7 250 | CPU x64 (sem GPU NVIDIA) | OK — FastEmbed usa ONNX em CPU |
| RAM | ~30 GB útil | 4–8 GB em runtime | OK |
| Disco livre (D:) | ~43 GB | ~3–6 GB (imagens + modelo) | OK |
| GPU AMD 780M | 2 GB | Não usada nesta POC | Irrelevante |

**Conclusão: viável.** Não há necessidade de GPU NVIDIA. O modelo padrão `paraphrase-multilingual-MiniLM-L12-v2` (~220 MB, dim 384) roda em CPU via ONNX e cobre português entre ~50 idiomas.

## Pré-requisitos

- Docker Desktop (WSL2 recomendado no Windows)
- ~6 GB livres no drive onde o Docker armazena dados

## Subir o ambiente

```powershell
cd D:\tmp\llm\FastEmbed
copy .env.example .env
docker compose up --build -d
```

> Portas padrão desta POC: API `8080`, Postgres `5433` (evitam conflito com serviços locais comuns em 8000/5432).

Na primeira subida a API baixa o modelo ONNX (pode levar alguns minutos). Acompanhe:

```powershell
docker compose logs -f api
```

Quando o health estiver ok:

- Swagger: http://localhost:8080/docs
- Health: http://localhost:8080/health

## Endpoints

| Método | Path | Descrição |
|--------|------|-----------|
| `GET` | `/health` | Status DB + modelo |
| `POST` | `/ingest` | Ingere documento/ata em PT |
| `POST` | `/search` | Busca semântica |
| `GET` | `/documents` | Lista documentos |
| `GET` | `/documents/{id}` | Detalhe do documento |

### Exemplo — ingest

```powershell
curl.exe -X POST http://localhost:8080/ingest `
  -H "Content-Type: application/json; charset=utf-8" `
  --data-binary "@scripts/sample_ata.json"
```

### Exemplo — busca

```powershell
curl.exe -X POST http://localhost:8080/search `
  -H "Content-Type: application/json; charset=utf-8" `
  --data-binary "@scripts/sample_search.json"
```

## Arquitetura

```
Cliente → FastAPI (/ingest, /search)
              ↓
         FastEmbed (paraphrase-multilingual-MiniLM, CPU/ONNX)
              ↓
         PostgreSQL + pgvector (HNSW / cosine)
```

Fluxo de ingestão:

1. Recebe texto PT
2. Divide em chunks com overlap
3. Gera embeddings (prefixo E5 `passage:`)
4. Persiste documento + chunks + vetores

Fluxo de busca:

1. Embedding da query (prefixo E5 `query:`)
2. Similaridade cosseno no pgvector
3. Retorna trechos mais relevantes com score

## Modelo e português

Padrão: `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` (384 dims, nativo no FastEmbed).

Alternativas (alinhar `EMBEDDING_DIM` e `vector(N)` em `sql/init.sql`):

| Modelo | Dim | Tamanho aprox. | Uso |
|--------|-----|----------------|-----|
| `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` | 384 | ~0.22 GB | POC (padrão) |
| `intfloat/multilingual-e5-small` | 384 | ~0.47 GB ONNX | Melhor retrieval (custom no FastEmbed) |
| `intfloat/multilingual-e5-large` | 1024 | ~2.2 GB | Máxima qualidade (nativo FastEmbed) |

Para trocar o modelo:

1. Ajuste `.env` (`EMBEDDING_MODEL`, `EMBEDDING_DIM`)
2. Ajuste `vector(N)` em `sql/init.sql`
3. Recrie volumes: `docker compose down -v && docker compose up --build -d`

> A primeira subida baixa o modelo (pode levar alguns minutos; downloads do Hugging Face às vezes avançam em rajadas).

## Parar / limpar

```powershell
docker compose down        # para containers
docker compose down -v     # para e apaga volumes (dados + cache do modelo)
```

## Limitações da POC

- Chunking por caracteres (não por tokens/sentenças NLP)
- Sem autenticação
- Sem OCR / parse de PDF-DOCX (envie texto puro no JSON)
- Uma réplica da API (modelo carregado em memória no container)
