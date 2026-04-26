from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Text, DateTime, Float
from sqlalchemy.orm import relationship
from .database import Base
from datetime import datetime

class Semester(Base):
    __tablename__ = "semesters"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    
class Subject(Base):
    __tablename__ = "subjects"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    semester_id = Column(Integer, ForeignKey("semesters.id"))
    exam_date = Column(DateTime, nullable=True)

class Note(Base):
    __tablename__ = "notes"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    content = Column(Text)
    subject_id = Column(Integer, ForeignKey("subjects.id"))

class Topic(Base):
    __tablename__ = "topics"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    subject_id = Column(Integer, ForeignKey("subjects.id"))
    status = Column(String, default="pending") # e.g. pending, reviewing, mastered

class Flashcard(Base):
    __tablename__ = "flashcards"
    id = Column(Integer, primary_key=True, index=True)
    question = Column(Text)
    answer = Column(Text)
    subject_id = Column(Integer, ForeignKey("subjects.id"))
    due_date = Column(DateTime, default=datetime.utcnow)
    # FSRS generic fields
    state = Column(Integer, default=0)
    stability = Column(Float, default=0.0)
    difficulty = Column(Float, default=0.0)
    elapsed_days = Column(Integer, default=0)
    scheduled_days = Column(Integer, default=0)
    reps = Column(Integer, default=0)
    lapses = Column(Integer, default=0)

class QuizSession(Base):
    __tablename__ = "quiz_sessions"
    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"))
    score = Column(Float, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class QuizAnswer(Base):
    __tablename__ = "quiz_answers"
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("quiz_sessions.id"))
    question = Column(Text)
    user_answer = Column(Text)
    correct = Column(Boolean)
    feedback = Column(Text, nullable=True)

class ExamPaper(Base):
    __tablename__ = "exam_papers"
    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"))
    content = Column(Text) # JSON string
    created_at = Column(DateTime, default=datetime.utcnow)

class PastPaper(Base):
    __tablename__ = "past_papers"
    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"))
    content = Column(Text)

class StudySession(Base):
    __tablename__ = "study_sessions"
    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"))
    duration_mins = Column(Integer)
    created_at = Column(DateTime, default=datetime.utcnow)

class PlannerNotification(Base):
    __tablename__ = "planner_notifications"
    id = Column(Integer, primary_key=True, index=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"))
    trigger_type = Column(String) # e.g. 1_month, 1_week, 1_day
    sent = Column(Boolean, default=False)
