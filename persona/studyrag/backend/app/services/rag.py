from .embeddings import query_similar
from .llm import call_groq

def answer(question: str, subject_id: int = None, exam_mode: bool = False) -> dict:
    results = query_similar(question, subject_id, top_k=4)
    
    context = ""
    source_ids = set()
    
    if results and results.get("documents") and len(results["documents"]) > 0:
        docs = results["documents"][0]
        metas = results["metadatas"][0]
        context = "\n---\n".join(docs)
        source_ids = {m.get("note_id") for m in metas if m.get("note_id")}
        
    system_prompt = (
        "You are an AI study assistant. Answer the user's question accurately using ONLY the provided context. "
        "If the answer is not in the context, say 'I cannot find the answer in your notes.' "
    )
    if exam_mode:
        system_prompt += "Return the answer strictly as a concise list of bullet points."
        
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": f"Context:\n{context}\n\nQuestion: {question}"}
    ]
    
    ans_text = call_groq(model="llama-3.3-70b-versatile", messages=messages, max_tokens=800)
    
    return {
        "answer": ans_text,
        "source_note_ids": list(source_ids)
    }
