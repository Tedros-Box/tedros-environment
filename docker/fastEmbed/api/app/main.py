from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from uuid import UUID

from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import RedirectResponse

from app import db
from app.chunking import chunk_text
from app.config import get_settings
from app.embeddings import get_embedding_service
from app.schemas import (
    DocumentSummary,
    HealthResponse,
    IngestRequest,
    IngestResponse,
    SearchHit,
    SearchRequest,
    SearchResponse,
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger("fastembed-api")


@asynccontextmanager
async def lifespan(_: FastAPI):
    settings = get_settings()
    logger.info("Starting API | model=%s dim=%s", settings.embedding_model, settings.embedding_dim)
    db.init_pool()
    emb = get_embedding_service()
    emb.load()
    yield
    db.close_pool()


app = FastAPI(
    title="FastEmbed + pgvector POC",
    description=(
        "API de ingestão e busca semântica para atas/transcrições e documentos em português. "
        "Usa FastEmbed (ONNX/CPU) + PostgreSQL/pgvector."
    ),
    version="0.1.0",
    lifespan=lifespan,
)


@app.get("/", include_in_schema=False)
def root():
    return RedirectResponse(url="/docs")


@app.get("/health", response_model=HealthResponse)
def health():
    settings = get_settings()
    emb = get_embedding_service()
    db_ok = db.check_db()
    return HealthResponse(
        status="ok" if db_ok and emb.ready else "degraded",
        database="up" if db_ok else "down",
        embedding_model=settings.embedding_model,
        embedding_dim=settings.embedding_dim,
        model_ready=emb.ready,
    )


@app.post("/ingest", response_model=IngestResponse)
def ingest(payload: IngestRequest):
    settings = get_settings()
    emb = get_embedding_service()

    chunks = chunk_text(
        payload.content,
        chunk_size=settings.chunk_size,
        overlap=settings.chunk_overlap,
    )
    if not chunks:
        raise HTTPException(status_code=400, detail="Conteúdo vazio após normalização")

    try:
        vectors = emb.embed_documents(chunks)
        document_id = db.insert_document_with_chunks(
            title=payload.title,
            doc_type=payload.doc_type,
            source=payload.source,
            metadata=payload.metadata,
            chunks=chunks,
            embeddings=vectors,
        )
    except Exception as exc:
        logger.exception("Falha no ingest")
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    return IngestResponse(
        document_id=document_id,
        title=payload.title,
        doc_type=payload.doc_type,
        chunks_created=len(chunks),
        embedding_model=settings.embedding_model,
        embedding_dim=settings.embedding_dim,
    )


@app.post("/search", response_model=SearchResponse)
def search(payload: SearchRequest):
    settings = get_settings()
    emb = get_embedding_service()

    try:
        query_vec = emb.embed_query(payload.query)
        rows = db.search_chunks(
            query_embedding=query_vec,
            top_k=payload.top_k,
            doc_type=payload.doc_type,
            document_id=payload.document_id,
        )
    except Exception as exc:
        logger.exception("Falha na busca")
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    hits = [
        SearchHit(
            chunk_id=row["chunk_id"],
            document_id=row["document_id"],
            title=row["title"],
            doc_type=row["doc_type"],
            chunk_index=row["chunk_index"],
            content=row["content"],
            score=float(row["score"]),
            metadata=row["metadata"] or {},
        )
        for row in rows
    ]
    return SearchResponse(query=payload.query, hits=hits, embedding_model=settings.embedding_model)


@app.get("/documents", response_model=list[DocumentSummary])
def list_documents(limit: int = Query(default=50, ge=1, le=200)):
    rows = db.list_documents(limit=limit)
    return [
        DocumentSummary(
            id=row["id"],
            title=row["title"],
            doc_type=row["doc_type"],
            source=row["source"],
            language=row["language"],
            chunk_count=row["chunk_count"],
            created_at=row["created_at"],
            metadata=row["metadata"] or {},
        )
        for row in rows
    ]


@app.get("/documents/{document_id}", response_model=DocumentSummary)
def get_document(document_id: UUID):
    row = db.get_document(document_id)
    if not row:
        raise HTTPException(status_code=404, detail="Documento não encontrado")
    return DocumentSummary(
        id=row["id"],
        title=row["title"],
        doc_type=row["doc_type"],
        source=row["source"],
        language=row["language"],
        chunk_count=row["chunk_count"],
        created_at=row["created_at"],
        metadata=row["metadata"] or {},
    )
