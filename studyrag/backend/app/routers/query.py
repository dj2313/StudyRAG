from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
from ..services.rag import answer

router = APIRouter(prefix="/query", tags=["query"])

class QueryRequest(BaseModel):
    question: str
    subject_id: Optional[int] = None
    semester_id: Optional[int] = None
    exam_mode: bool = False

@router.post("")
def ask_question(request: QueryRequest):
    return answer(request.question, request.subject_id, request.exam_mode)
