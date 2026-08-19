from __future__ import annotations

import json
from contextlib import contextmanager
from typing import Any, Iterator
from uuid import UUID

from psycopg import Connection
from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool

from app.config import get_settings

_pool: ConnectionPool | None = None


def init_pool() -> ConnectionPool:
    global _pool
    if _pool is None:
        settings = get_settings()
        _pool = ConnectionPool(
            conninfo=settings.database_url,
            min_size=1,
            max_size=8,
            kwargs={"row_factory": dict_row},
            open=True,
        )
    return _pool


def close_pool() -> None:
    global _pool
    if _pool is not None:
        _pool.close()
        _pool = None


@contextmanager
def get_conn() -> Iterator[Connection]:
    pool = init_pool()
    with pool.connection() as conn:
        yield conn


def check_db() -> bool:
    try:
        with get_conn() as conn:
            conn.execute("SELECT 1")
        return True
    except Exception:
        return False


def insert_document_with_chunks(
    *,
    title: str,
    doc_type: str,
    source: str | None,
    metadata: dict[str, Any],
    chunks: list[str],
    embeddings: list[list[float]],
) -> UUID:
    if len(chunks) != len(embeddings):
        raise ValueError("chunks and embeddings length mismatch")

    with get_conn() as conn:
        with conn.transaction():
            doc = conn.execute(
                """
                INSERT INTO documents (title, doc_type, source, language, metadata)
                VALUES (%s, %s, %s, 'pt', %s::jsonb)
                RETURNING id
                """,
                (title, doc_type, source, json.dumps(metadata, ensure_ascii=False)),
            ).fetchone()
            assert doc is not None
            document_id: UUID = doc["id"]

            for idx, (content, embedding) in enumerate(zip(chunks, embeddings)):
                vector_literal = "[" + ",".join(str(float(x)) for x in embedding) + "]"
                conn.execute(
                    """
                    INSERT INTO chunks (
                        document_id, chunk_index, content, token_estimate, embedding, metadata
                    )
                    VALUES (
                        %s, %s, %s, %s, %s::vector, '{}'::jsonb
                    )
                    """,
                    (
                        document_id,
                        idx,
                        content,
                        max(1, len(content.split())),
                        vector_literal,
                    ),
                )

            return document_id


def search_chunks(
    *,
    query_embedding: list[float],
    top_k: int = 5,
    doc_type: str | None = None,
    document_id: UUID | None = None,
) -> list[dict[str, Any]]:
    vector_literal = "[" + ",".join(str(float(x)) for x in query_embedding) + "]"
    filters = ["c.embedding IS NOT NULL"]
    params: list[Any] = [vector_literal]

    if doc_type:
        filters.append("d.doc_type = %s")
        params.append(doc_type)
    if document_id:
        filters.append("d.id = %s")
        params.append(document_id)

    where_sql = " AND ".join(filters)
    params.extend([vector_literal, top_k])

    sql = f"""
        SELECT
            c.id AS chunk_id,
            d.id AS document_id,
            d.title,
            d.doc_type,
            c.chunk_index,
            c.content,
            c.metadata,
            1 - (c.embedding <=> %s::vector) AS score
        FROM chunks c
        JOIN documents d ON d.id = c.document_id
        WHERE {where_sql}
        ORDER BY c.embedding <=> %s::vector
        LIMIT %s
    """

    with get_conn() as conn:
        rows = conn.execute(sql, params).fetchall()
        return list(rows)


def list_documents(limit: int = 50) -> list[dict[str, Any]]:
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT
                d.id,
                d.title,
                d.doc_type,
                d.source,
                d.language,
                d.metadata,
                d.created_at,
                COUNT(c.id)::int AS chunk_count
            FROM documents d
            LEFT JOIN chunks c ON c.document_id = d.id
            GROUP BY d.id
            ORDER BY d.created_at DESC
            LIMIT %s
            """,
            (limit,),
        ).fetchall()
        return list(rows)


def get_document(document_id: UUID) -> dict[str, Any] | None:
    with get_conn() as conn:
        row = conn.execute(
            """
            SELECT
                d.id,
                d.title,
                d.doc_type,
                d.source,
                d.language,
                d.metadata,
                d.created_at,
                COUNT(c.id)::int AS chunk_count
            FROM documents d
            LEFT JOIN chunks c ON c.document_id = d.id
            WHERE d.id = %s
            GROUP BY d.id
            """,
            (document_id,),
        ).fetchone()
        return dict(row) if row else None
