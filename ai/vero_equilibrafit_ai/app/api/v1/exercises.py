from fastapi import APIRouter

from app.core.config import get_settings
from app.schemas.exercises import ExerciseCandidate, ExerciseSuggestionRequest
from app.services.exercise_service import ExerciseService

router = APIRouter(tags=["exercises"])


@router.post("/api/v1/exercises/suggest", response_model=ExerciseCandidate)
async def suggest_exercise(request: ExerciseSuggestionRequest) -> ExerciseCandidate:
    return await ExerciseService(get_settings()).suggest(request)
