from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql://fastembed:fastembed@db:5432/fastembed"
    embedding_model: str = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
    embedding_dim: int = 384
    chunk_size: int = 500
    chunk_overlap: int = 80
    fastembed_cache_path: str = "/cache/fastembed"


@lru_cache
def get_settings() -> Settings:
    return Settings()
