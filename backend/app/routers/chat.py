"""
NexRide Backend - Chat Router
POST /chat  — Hybrid AI chatbot endpoint
"""
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.services.intent_detector import detect_intent
from app.services.entity_extractor import extract_entities
from app.services.chatbot_service  import process_message

router = APIRouter(prefix="/chat", tags=["Chatbot"])


class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    reply:    str
    intent:   str
    entities: dict


@router.post("/", response_model=ChatResponse)
def chat(payload: ChatRequest, db: Session = Depends(get_db)):
    """
    Hybrid AI chatbot: keyword intent + entity extraction + backend logic + optional LLM polish.
    """
    msg      = payload.message.strip()
    intent   = detect_intent(msg)
    entities = extract_entities(msg)
    reply    = process_message(intent, entities, msg, db)

    return ChatResponse(reply=reply, intent=intent, entities=entities)
