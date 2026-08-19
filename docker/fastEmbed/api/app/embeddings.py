from __future__ import annotations

import logging
import threading
from functools import lru_cache

from fastembed import TextEmbedding
from fastembed.common.model_description import ModelSource, PoolingType

from app.config import get_settings

logger = logging.getLogger(__name__)

# Models that expect E5-style prefixes for better retrieval quality
_E5_PREFIX_MODELS = {
    "intfloat/multilingual-e5-small",
    "intfloat/multilingual-e5-base",
    "intfloat/multilingual-e5-large",
    "intfloat/e5-small",
    "intfloat/e5-base",
    "intfloat/e5-large",
}

_CUSTOM_MODELS = {
    "intfloat/multilingual-e5-small": {
        "dim": 384,
        "pooling": PoolingType.MEAN,
        "model_file": "onnx/model.onnx",
    },
    "intfloat/multilingual-e5-base": {
        "dim": 768,
        "pooling": PoolingType.MEAN,
        "model_file": "onnx/model.onnx",
    },
}


class EmbeddingService:
    def __init__(self) -> None:
        self.settings = get_settings()
        self.model_name = self.settings.embedding_model
        self.dim = self.settings.embedding_dim
        self._model: TextEmbedding | None = None
        self._lock = threading.Lock()
        self._ready = False

    @property
    def ready(self) -> bool:
        return self._ready

    def _register_custom_model_if_needed(self) -> None:
        if self.model_name not in _CUSTOM_MODELS:
            return

        cfg = _CUSTOM_MODELS[self.model_name]
        try:
            TextEmbedding.add_custom_model(
                model=self.model_name,
                pooling=cfg["pooling"],
                normalization=True,
                sources=ModelSource(hf=self.model_name),
                dim=cfg["dim"],
                model_file=cfg["model_file"],
            )
            logger.info("Registered custom FastEmbed model: %s", self.model_name)
        except ValueError as exc:
            # Already registered (e.g. reload / multiple workers)
            if "already registered" not in str(exc).lower():
                raise

    def load(self) -> None:
        with self._lock:
            if self._model is not None:
                return

            self._register_custom_model_if_needed()
            logger.info("Loading FastEmbed model %s ...", self.model_name)
            self._model = TextEmbedding(
                model_name=self.model_name,
                cache_dir=self.settings.fastembed_cache_path,
            )
            # Warm-up: forces ONNX download/load on startup
            _ = list(self._model.embed(["passage: aquecimento do modelo"]))
            self._ready = True
            logger.info("Model ready: %s (dim=%s)", self.model_name, self.dim)

    def _ensure_loaded(self) -> TextEmbedding:
        if self._model is None:
            self.load()
        assert self._model is not None
        return self._model

    def _prefix_passages(self, texts: list[str]) -> list[str]:
        if self.model_name in _E5_PREFIX_MODELS:
            return [t if t.startswith("passage:") else f"passage: {t}" for t in texts]
        return texts

    def _prefix_query(self, query: str) -> str:
        if self.model_name in _E5_PREFIX_MODELS:
            return query if query.startswith("query:") else f"query: {query}"
        return query

    def embed_documents(self, texts: list[str]) -> list[list[float]]:
        """Embed passages. Uses explicit E5 prefixes via embed() to avoid double-prefixing."""
        model = self._ensure_loaded()
        prefixed = self._prefix_passages(texts)
        # Use embed() (not passage helpers) so custom E5 models get a single, explicit prefix
        vectors = [vec.tolist() for vec in model.embed(prefixed)]
        self._validate_dims(vectors)
        return vectors

    def embed_query(self, query: str) -> list[float]:
        model = self._ensure_loaded()
        prefixed = self._prefix_query(query)
        # Same path as documents: one explicit prefix, no query_embed auto-prefix
        vector = next(model.embed([prefixed])).tolist()
        if len(vector) != self.dim:
            raise ValueError(
                f"Embedding dim mismatch: got {len(vector)}, expected {self.dim}"
            )
        return vector

    def _validate_dims(self, vectors: list[list[float]]) -> None:
        for vec in vectors:
            if len(vec) != self.dim:
                raise ValueError(
                    f"Embedding dim mismatch: got {len(vec)}, expected {self.dim}. "
                    "Ajuste EMBEDDING_DIM e o schema SQL (vector(N))."
                )


@lru_cache
def get_embedding_service() -> EmbeddingService:
    return EmbeddingService()
