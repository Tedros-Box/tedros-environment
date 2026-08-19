def chunk_text(text: str, chunk_size: int = 500, overlap: int = 80) -> list[str]:
    """Split Portuguese documents into overlapping character windows.

    Character-based chunking is simple and language-agnostic; good enough for a POC.
    For production, prefer sentence-aware or token-based splitters.
    """
    cleaned = " ".join(text.split())
    if not cleaned:
        return []

    if len(cleaned) <= chunk_size:
        return [cleaned]

    if overlap >= chunk_size:
        overlap = max(0, chunk_size // 5)

    chunks: list[str] = []
    start = 0
    text_len = len(cleaned)

    while start < text_len:
        end = min(start + chunk_size, text_len)

        # Prefer breaking on sentence/punctuation boundaries near the window end
        if end < text_len:
            window = cleaned[start:end]
            for sep in (". ", "! ", "? ", "; ", ": ", ", "):
                idx = window.rfind(sep)
                if idx >= chunk_size // 2:
                    end = start + idx + len(sep)
                    break

        piece = cleaned[start:end].strip()
        if piece:
            chunks.append(piece)

        if end >= text_len:
            break

        start = max(0, end - overlap)

    return chunks
