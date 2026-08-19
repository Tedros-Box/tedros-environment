import urllib.request

for name, url in [
    ("hf", "https://huggingface.co"),
    ("gcs", "https://storage.googleapis.com/qdrant-fastembed/fast-multilingual-e5-large.tar.gz"),
]:
    try:
        with urllib.request.urlopen(url, timeout=20) as resp:
            print(name, resp.status, resp.getheader("Content-Length"))
    except Exception as exc:
        print(name, "FAIL", type(exc).__name__, exc)
