from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from ..database import get_db
from ..models import Subject, Topic, PlannerNotification

router = APIRouter(prefix="/planner", tags=["planner"])

class ExamDateReq(BaseModel):
    subject_id: int
    date: str

class TopicStatusReq(BaseModel):
    topic_id: int
    status: str

class MarkSentReq(BaseModel):
    notification_id: int

@router.get("")
def get_planner(db: Session = Depends(get_db)):
    subjects = db.query(Subject).all()
    now = datetime.utcnow()
    result = []
    
    for s in subjects:
        days_rem = None
        if s.exam_date:
            days_rem = (s.exam_date - now).days
            trigger = None
            if days_rem == 30: trigger = "1_month"
            elif days_rem == 7: trigger = "1_week"
            elif days_rem == 1: trigger = "1_day"
            
            if trigger:
                existing = db.query(PlannerNotification).filter(
                    PlannerNotification.subject_id == s.id,
                    PlannerNotification.trigger_type == trigger
                ).first()
                if not existing:
                    db.add(PlannerNotification(subject_id=s.id, trigger_type=trigger))
                    db.commit()
                    
        topics = db.query(Topic).filter(Topic.subject_id == s.id).all()
        result.append({
            "subject_id": s.id,
            "name": s.name,
            "exam_date": s.exam_date.isoformat() if s.exam_date else None,
            "days_remaining": days_rem,
            "topics": [{"id": t.id, "name": t.name, "status": t.status} for t in topics]
        })
    return result

@router.post("/exam-date")
def set_exam_date(req: ExamDateReq, db: Session = Depends(get_db)):
    s = db.query(Subject).filter(Subject.id == req.subject_id).first()
    if not s: raise HTTPException(status_code=404, detail="Subject not found")
    try:
        s.exam_date = datetime.strptime(req.date, "%Y-%m-%d")
        db.commit()
        return {"message": "Exam date updated"}
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date, use YYYY-MM-DD")

@router.put("/topic-status")
def set_topic_status(req: TopicStatusReq, db: Session = Depends(get_db)):
    t = db.query(Topic).filter(Topic.id == req.topic_id).first()
    if not t: raise HTTPException(status_code=404, detail="Topic not found")
    t.status = req.status
    db.commit()
    return {"message": "Status updated"}

@router.get("/notifications")
def get_notifications(db: Session = Depends(get_db)):
    nots = db.query(PlannerNotification).filter(PlannerNotification.sent == False).all()
    res = []
    for n in nots:
        s = db.query(Subject).filter(Subject.id == n.subject_id).first()
        res.append({
            "id": n.id,
            "subject_id": n.subject_id,
            "subject_name": s.name if s else "Unknown",
            "trigger_type": n.trigger_type
        })
    return res

@router.post("/mark-sent")
def mark_sent(req: MarkSentReq, db: Session = Depends(get_db)):
    n = db.query(PlannerNotification).filter(PlannerNotification.id == req.notification_id).first()
    if n:
        n.sent = True
        db.commit()
    return {"message": "Marked as sent"}
