from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
import json
import os
import shutil
import uuid
from ..database import get_db
from ..models import ExamPaper, PastPaper, Topic
from ..services.llm import call_groq
from ..services.embeddings import collection
from ..services import ocr

router = APIRouter(prefix="/exam", tags=["exam"])
UPLOAD_DIR = "./uploads"

class ExamGenerateReq(BaseModel):
    subject_id: int
    duration_mins: int = 60
    count: int = 10
    source: str = "notes"

class AnswerItem(BaseModel):
    question: str
    user_answer: str
    topic: str

class ExamSubmitReq(BaseModel):
    paper_id: int
    answers: List[AnswerItem]

@router.post("/generate")
def generate_exam(req: ExamGenerateReq, db: Session = Depends(get_db)):
    context = ""
    
    if req.source in ["notes", "both"]:
        results = collection.get(where={"subject_id": req.subject_id})
        if results and results.get("documents"):
            context += "NOTES:\n" + "\n---\n".join(results["documents"][:5]) + "\n\n"
            
    if req.source in ["past_papers", "both"]:
        papers = db.query(PastPaper).filter(PastPaper.subject_id == req.subject_id).limit(2).all()
        if papers:
            context += "PAST EXAM QUESTIONS:\n" + "\n---\n".join([p.content for p in papers]) + "\n\n"
            
    if not context:
        raise HTTPException(status_code=404, detail="No source material found")
        
    sys_prompt = f"Generate a mock exam with {req.count} questions. Duration: {req.duration_mins} mins. Return JSON array: [{{\"question\":\"...\", \"topic\":\"...\"}}]. Only JSON."
    ans = call_groq(model="llama-3.3-70b-versatile", messages=[
        {"role": "system", "content": sys_prompt},
        {"role": "user", "content": f"Material:\n{context}"}
    ], max_tokens=1500)
    
    try:
        ans = ans.strip()
        if ans.startswith("```json"): ans = ans[7:]
        if ans.endswith("```"): ans = ans[:-3]
        
        questions = json.loads(ans.strip())
        paper = ExamPaper(subject_id=req.subject_id, content=json.dumps(questions))
        db.add(paper)
        db.commit()
        db.refresh(paper)
        return {"paper_id": paper.id, "questions": questions}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to parse: {str(e)}\nRaw: {ans}")

@router.post("/submit")
def submit_exam(req: ExamSubmitReq, db: Session = Depends(get_db)):
    paper = db.query(ExamPaper).filter(ExamPaper.id == req.paper_id).first()
    if not paper: raise HTTPException(status_code=404, detail="Paper not found")
        
    batch_prompt = "Grade these exam answers. Return JSON: [{\"score\": 0.0_to_1.0, \"feedback\": \"...\"}]. Only JSON.\n"
    for i, a in enumerate(req.answers):
        batch_prompt += f"Q{i}: {a.question}\nA{i}: {a.user_answer}\n---\n"
        
    ans = call_groq(model="llama-3.3-70b-versatile", messages=[{"role": "user", "content": batch_prompt}], max_tokens=1500)
    
    try:
        ans = ans.strip()
        if ans.startswith("```json"): ans = ans[7:]
        if ans.endswith("```"): ans = ans[:-3]
        grades = json.loads(ans.strip())
        
        total_score = 0
        feedback_items = []
        weak_topics = set()
        
        for i, grade in enumerate(grades):
            score_val = float(grade["score"])
            total_score += score_val
            if score_val < 0.6: weak_topics.add(req.answers[i].topic)
            feedback_items.append({"question": req.answers[i].question, "score": score_val, "feedback": grade["feedback"]})
            
        final_score = (total_score / len(req.answers)) * 100 if req.answers else 0
        
        for topic_name in weak_topics:
            t = db.query(Topic).filter(Topic.name == topic_name, Topic.subject_id == paper.subject_id).first()
            if not t: db.add(Topic(name=topic_name, subject_id=paper.subject_id, status="reviewing"))
            else: t.status = "reviewing"
                
        db.commit()
        return {"score": final_score, "feedback": feedback_items, "weak_topics": list(weak_topics)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Grading failed: {str(e)}\nRaw: {ans}")

@router.get("/result/{paper_id}")
def get_result(paper_id: int):
    return {"message": "Not fully implemented"}

@router.post("/upload-past-paper")
def upload_past_paper(subject_id: int = Form(...), file: UploadFile = File(...), db: Session = Depends(get_db)):
    path = os.path.join(UPLOAD_DIR, f"{uuid.uuid4()}_{file.filename}")
    with open(path, "wb") as buf: shutil.copyfileobj(file.file, buf)
        
    try:
        text = ocr.route_file(path, file.content_type or "")
        sys_prompt = "Extract questions from this past paper. Return JSON: [\"Q1...\", \"Q2...\"]. Only JSON."
        ans = call_groq(model="llama-3.1-8b-instant", messages=[
            {"role": "system", "content": sys_prompt},
            {"role": "user", "content": f"Text: {text[:4000]}"}
        ])
        ans = ans.strip()
        if ans.startswith("```json"): ans = ans[7:]
        if ans.endswith("```"): ans = ans[:-3]
        
        questions = json.loads(ans.strip())
        pp = PastPaper(subject_id=subject_id, content=json.dumps(questions))
        db.add(pp)
        db.commit()
        return {"message": f"Extracted {len(questions)} questions"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if os.path.exists(path): os.remove(path)
