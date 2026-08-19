from datetime import datetime
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel, Field


DocType = Literal["ata", "documento", "transcricao", "outro"]


class IngestRequest(BaseModel):
    title: str = Field(..., min_length=1, max_length=500)
    content: str = Field(..., min_length=1, description="Texto completo em português")
    doc_type: DocType = "ata"
    source: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)


class IngestResponse(BaseModel):
    document_id: UUID
    title: str
    doc_type: str
    chunks_created: int
    embedding_model: str
    embedding_dim: int


class SearchRequest(BaseModel):
    query: str = Field(..., min_length=1, max_length=2000)
    top_k: int = Field(default=5, ge=1, le=50)
    doc_type: DocType | None = None
    document_id: UUID | None = None


class SearchHit(BaseModel):
    chunk_id: UUID
    document_id: UUID
    title: str
    doc_type: str
    chunk_index: int
    content: str
    score: float
    metadata: dict[str, Any] = Field(default_factory=dict)


class SearchResponse(BaseModel):
    query: str
    hits: list[SearchHit]
    embedding_model: str


class DocumentSummary(BaseModel):
    id: UUID
    title: str
    doc_type: str
    source: str | None
    language: str
    chunk_count: int
    created_at: datetime
    metadata: dict[str, Any] = Field(default_factory=dict)


class HealthResponse(BaseModel):
    status: str
    database: str
    embedding_model: str
    embedding_dim: int
    model_ready: bool
