# tests/test_retrieval.py
from app.services.retrieval.embeddings import embed_text

def test_embedding():
    vec = embed_text("hello world")
    assert isinstance(vec, list)
    assert len(vec) > 0
