from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
import json
from ..database import get_db
from ..models import QuizSession, QuizAnswer, Topic
from ..services.llm import call_groq
from ..services.embeddings import collection

router = APIRouter(prefix="/quiz", tags=["quiz"])

class QuizGenerateReq(BaseModel):
    subject_id: int
    count: int = 5
    type: str = "mcq"

class AnswerItem(BaseModel):
    question: str
    user_answer: str
    topic: str
    correct_answer: Optional[str] = None

class QuizSubmitReq(BaseModel):
    session_id: int
    answers: List[AnswerItem]

@router.post("/generate")
def generate_quiz(req: QuizGenerateReq, db: Session = Depends(get_db)):
    results = collection.get(where={"subject_id": req.subject_id})
    if not results or not results.get("documents"):
        raise HTTPException(status_code=404, detail="No notes found")
        
    context = "\n---\n".join(results["documents"][:5])
    
    if req.type == "mcq":
        sys_prompt = f"Generate {req.count} MCQ questions from the text.\nReturn JSON: [{{\"question\":\"...\",\"options\":[\"A\",\"B\",\"C\",\"D\"],\"answer\":\"A\",\"topic\":\"...\"}}]\nOnly JSON."
    else:
        sys_prompt = f"Generate {req.count} short answer questions from the text.\nReturn JSON: [{{\"question\":\"...\",\"topic\":\"...\"}}]\nOnly JSON."
        
    ans = call_groq(model="llama-3.1-8b-instant", messages=[
        {"role": "system", "content": sys_prompt},
        {"role": "user", "content": f"Text: {context}"}
    ], max_tokens=800)
    
    try:
        ans = ans.strip()
        if ans.startswith("```json"): ans = ans[7:]
        if ans.endswith("```"): ans = ans[:-3]
        
        quiz_data = json.loads(ans.strip())
        session = QuizSession(subject_id=req.subject_id)
        db.add(session)
        db.commit()
        db.refresh(session)
        return {"session_id": session.id, "questions": quiz_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Generation failed: {str(e)}\nRaw: {ans}")

@router.post("/submit")
def submit_quiz(req: QuizSubmitReq, db: Session = Depends(get_db)):
    session = db.query(QuizSession).filter(QuizSession.id == req.session_id).first()
    if not session: raise HTTPException(status_code=404, detail="Session not found")
        
    score = 0
    total = len(req.answers)
    weak_topics = set()
    feedback_items = []
    short_answers = []
    
    for a in req.answers:
        if a.correct_answer:
            is_correct = (a.user_answer.strip().lower() == a.correct_answer.strip().lower())
            if is_correct: score += 1
            else: weak_topics.add(a.topic)
            qa = QuizAnswer(session_id=session.id, question=a.question, user_answer=a.user_answer, correct=is_correct)
            db.add(qa)
            feedback_items.append({"question": a.question, "correct": is_correct, "feedback": f"Correct: {a.correct_answer}"})
        else:
            short_answers.append(a)
            
    if short_answers:
        batch_prompt = "Grade these short answers. Return JSON: [{\"correct\": true|false, \"feedback\": \"...\"}]. Only JSON.\n"
        for i, sa in enumerate(short_answers):
            batch_prompt += f"Q{i}: {sa.question}\nA{i}: {sa.user_answer}\n---\n"
            
        eval_res = call_groq(model="llama-3.1-8b-instant", messages=[{"role": "user", "content": batch_prompt}])
        try:
            eval_res = eval_res.strip()
            if eval_res.startswith("```json"): eval_res = eval_res[7:]
            if eval_res.endswith("```"): eval_res = eval_res[:-3]
            grades = json.loads(eval_res.strip())
            
            for i, sa in enumerate(short_answers):
                is_correct = grades[i]["correct"]
                fb = grades[i]["feedback"]
                if is_correct: score += 1
                else: weak_topics.add(sa.topic)
                qa = QuizAnswer(session_id=session.id, question=sa.question, user_answer=sa.user_answer, correct=is_correct, feedback=fb)
                db.add(qa)
                feedback_items.append({"question": sa.question, "correct": is_correct, "feedback": fb})
        except: pass
            
    session.score = (score / total) * 100 if total > 0 else 0
    
    for topic_name in weak_topics:
        t = db.query(Topic).filter(Topic.name == topic_name, Topic.subject_id == session.subject_id).first()
        if not t: db.add(Topic(name=topic_name, subject_id=session.subject_id, status="reviewing"))
        else: t.status = "reviewing"
            
    db.commit()
    return {"score": session.score, "weak_topics": list(weak_topics), "feedback": feedback_items}

@router.get("/history/{subject_id}")
def get_history(subject_id: int, db: Session = Depends(get_db)):
    return db.query(QuizSession).filter(QuizSession.subject_id == subject_id).all()
