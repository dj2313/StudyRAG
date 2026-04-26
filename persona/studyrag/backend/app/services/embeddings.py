import chromadb
import requests
from ..config import settings

chroma_client = chromadb.PersistentClient(path=settings.CHROMA_DB_PATH)
collection = chroma_client.get_or_create_collection(name="study_notes")

def get_embedding(text: str) -> list:
    res = requests.post(
        f"{settings.OLLAMA_BASE_URL}/api/embeddings",
        json={"model": "nomic-embed-text", "prompt": text}
    )
    return res.json().get("embedding", []) if res.status_code == 200 else []

def chunk_text(text: str, size: int, overlap: int) -> list:
    return [text[i:i+size] for i in range(0, len(text), size - overlap)] if text else []

def embed_and_store(text: str, metadata: dict):
    chunks = chunk_text(text, settings.MAX_CHUNK_SIZE, 100)
    ids, embeddings, documents, metadatas = [], [], [], []
    
    for i, chunk in enumerate(chunks):
        embed = get_embedding(chunk)
        if embed:
            ids.append(f"{metadata.get('note_id', 'note')}_{i}")
            embeddings.append(embed)
            documents.append(chunk)
            metadatas.append(metadata)
            
    if ids:
        collection.add(ids=ids, embeddings=embeddings, documents=documents, metadatas=metadatas)

def query_similar(question: str, subject_id: int, top_k: int = settings.TOP_K_RETRIEVAL) -> list:
    embed = get_embedding(question)
    where_clause = {"subject_id": subject_id} if subject_id else None
    return collection.query(
        query_embeddings=[embed],
        n_results=top_k,
        where=where_clause
    )
