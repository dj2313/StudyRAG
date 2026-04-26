from fastapi import APIRouter, UploadFile, File, Form, Depends, BackgroundTasks
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import Note
from ..services import ocr, embeddings
from groq import Groq
from ..config import settings
import os
import shutil
import uuid

router = APIRouter(prefix="/ingest", tags=["ingest"])
UPLOAD_DIR = "./uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
status_map = {}

def process_file(note_id: int, path: str, mime: str, meta: dict, db: Session):
    status_map[note_id] = "processing"
    try:
        text = ocr.route_file(path, mime)
        note = db.query(Note).filter(Note.id == note_id).first()
        note.content = text
        db.commit()
        embeddings.embed_and_store(text, meta)
        status_map[note_id] = "completed"
    except Exception as e:
        status_map[note_id] = f"error: {str(e)}"
    finally:
        if os.path.exists(path): os.remove(path)

@router.post("/file")
def ingest_file(bg: BackgroundTasks, subject_id: int = Form(...), file: UploadFile = File(...), db: Session = Depends(get_db)):
    note = Note(title=file.filename, subject_id=subject_id, content="Indexing...")
    db.add(note)
    db.commit()
    db.refresh(note)
    
    path = os.path.join(UPLOAD_DIR, f"{uuid.uuid4()}_{file.filename}")
    with open(path, "wb") as buf: shutil.copyfileobj(file.file, buf)
        
    status_map[note.id] = "queued"
    bg.add_task(process_file, note.id, path, file.content_type or "", {"note_id": note.id, "subject_id": subject_id}, db)
    return {"message": "Queued", "note_id": note.id}

@router.post("/voice")
def ingest_voice(subject_id: int = Form(...), file: UploadFile = File(...), db: Session = Depends(get_db)):
    client = Groq(api_key=settings.GROQ_API_KEY)
    note = Note(title=f"Voice {uuid.uuid4().hex[:6]}", subject_id=subject_id, content="Transcribing...")
    db.add(note)
    db.commit()
    db.refresh(note)
    
    path = os.path.join(UPLOAD_DIR, f"{uuid.uuid4()}_{file.filename}")
    with open(path, "wb") as buf: shutil.copyfileobj(file.file, buf)
        
    try:
        with open(path, "rb") as audio:
            res = client.audio.transcriptions.create(file=(file.filename, audio.read()), model="whisper-large-v3")
        note.content = res.text
        db.commit()
        embeddings.embed_and_store(res.text, {"note_id": note.id, "subject_id": subject_id, "type": "voice"})
        status_map[note.id] = "completed"
    except Exception as e:
        status_map[note.id] = f"error: {str(e)}"
    finally:
        if os.path.exists(path): os.remove(path)
    return {"message": "Processed", "note_id": note.id, "text": note.content}

@router.get("/status/{note_id}")
def get_status(note_id: int):
    return {"note_id": note_id, "status": status_map.get(note_id, "not found")}