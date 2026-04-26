from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from .routers import ingest, query, flashcards, quiz, planner, exam

# Create all tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="StudyRAG API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(ingest.router)
app.include_router(query.router)
app.include_router(flashcards.router)
app.include_router(quiz.router)
app.include_router(planner.router)
app.include_router(exam.router)

@app.get("/")
def read_root():
    return {"message": "StudyRAG Backend is running"}
