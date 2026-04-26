from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
import json
from ..database import get_db
from ..models import Flashcard
from ..services.fsrs import get_due_cards, update_card
from ..services.llm import call_groq
from ..services.embeddings import collection

router = APIRouter(prefix="/flashcards", tags=["flashcards"])

class ReviewRequest(BaseModel):
    card_id: int
    rating: int

class FlashcardCreate(BaseModel):
    subject_id: int
    question: str
    answer: str

@router.post("/generate/{subject_id}")
def generate_flashcards(subject_id: int, count: int = 10, db: Session = Depends(get_db)):
    results = collection.get(where={"subject_id": subject_id})
    if not results or not results.get("documents"):
        raise HTTPException(status_code=404, detail="No notes found for subject")
    
    context = "\n---\n".join(results["documents"][:5])
    sys_prompt = f"Generate {count} flashcards from the text below.\nReturn JSON array: [{{\"question\": \"...\", \"answer\": \"...\"}}]\nOnly return JSON, no extra text."
    
    ans = call_groq(model="llama-3.1-8b-instant", messages=[
        {"role": "system", "content": sys_prompt},
        {"role": "user", "content": f"Text: {context}"}
    ], max_tokens=800)
    
    try:
        ans = ans.strip()
        if ans.startswith("```json"): ans = ans[7:]
        if ans.endswith("```"): ans = ans[:-3]
        
        cards = json.loads(ans.strip())
        new_cards = [Flashcard(subject_id=subject_id, question=c["question"], answer=c["answer"]) for c in cards]
        db.add_all(new_cards)
        db.commit()
        return {"message": f"Generated {len(new_cards)} flashcards"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed: {str(e)} Raw: {ans}")

@router.get("/{subject_id}")
def get_due(subject_id: int, db: Session = Depends(get_db)):
    return get_due_cards(db, subject_id)

@router.post("/review")
def review(req: ReviewRequest, db: Session = Depends(get_db)):
    fc = update_card(db, req.card_id, req.rating)
    if not fc: raise HTTPException(status_code=404, detail="Not found")
    return fc

@router.post("")
def create_manual(req: FlashcardCreate, db: Session = Depends(get_db)):
    fc = Flashcard(**req.dict())
    db.add(fc)
    db.commit()
    db.refresh(fc)
    return fc

@router.delete("/{card_id}")
def delete_card(card_id: int, db: Session = Depends(get_db)):
    fc = db.query(Flashcard).filter(Flashcard.id == card_id).first()
    if not fc: raise HTTPException(status_code=404, detail="Not found")
    db.delete(fc)
    db.commit()
    return {"message": "Deleted"}
