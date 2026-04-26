from fsrs import FSRS, Card, Rating
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from ..models import Flashcard

scheduler = FSRS()

def get_due_cards(db: Session, subject_id: int):
    now = datetime.utcnow()
    return db.query(Flashcard).filter(
        Flashcard.subject_id == subject_id,
        Flashcard.due_date <= now
    ).all()

def update_card(db: Session, card_id: int, rating: int):
    fc = db.query(Flashcard).filter(Flashcard.id == card_id).first()
    if not fc: return None
    
    card = Card()
    card.state = fc.state
    card.stability = fc.stability
    card.difficulty = fc.difficulty
    card.elapsed_days = fc.elapsed_days
    card.scheduled_days = fc.scheduled_days
    card.reps = fc.reps
    card.lapses = fc.lapses
    
    now = datetime.utcnow().replace(tzinfo=timezone.utc)
    r = Rating(rating)
    scheduling_cards = scheduler.repeat(card, now)
    scheduled_card = scheduling_cards[r].card
    
    fc.state = scheduled_card.state
    fc.stability = scheduled_card.stability
    fc.difficulty = scheduled_card.difficulty
    fc.elapsed_days = scheduled_card.elapsed_days
    fc.scheduled_days = scheduled_card.scheduled_days
    fc.reps = scheduled_card.reps
    fc.lapses = scheduled_card.lapses
    fc.due_date = scheduled_card.due.replace(tzinfo=None)
    
    db.commit()
    db.refresh(fc)
    return fc
