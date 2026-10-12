from typing import Literal
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    environment: str = "development"
    internal_api_key: str = ""
    gemini_api_key: str = ""
    gemini_model: str = "gemini-3.5-flash-lite"

class ExerciseCandidate(BaseModel):
    status: Literal["existing_match", "new_candidate", "needs_clarification"]
    existing_exercise_id: str | None = None
    name: str | None = None
    aliases: list[str] = Field(default_factory=list)
    primary_muscle: str | None = None
    secondary_muscles: list[str] = Field(default_factory=list)
    equipment: str | None = None
    difficulty: str | None = None
    instructions: list[str] = Field(default_factory=list)
    common_errors: list[str] = Field(default_factory=list)
    safety_tips: list[str] = Field(default_factory=list)
    alternatives: list[str] = Field(default_factory=list)
    requires_user_confirmation: Literal[True] = True

app = FastAPI(title="VeroEqulibraFit+ AI", docs_url=None)
settings = Settings()

@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "healthy", "provider": "gemini", "model": settings.gemini_model}

@app.post("/internal/v1/exercises/suggest", response_model=ExerciseCandidate)
async def suggest_exercise(query: str, x_internal_api_key: str | None = Header(default=None)) -> ExerciseCandidate:
    if settings.environment == "production" and (not settings.internal_api_key or x_internal_api_key != settings.internal_api_key):
        raise HTTPException(status_code=401, detail="internal authentication required")
    # A live Gemini request is intentionally not made without a configured server key.
    # The API must have completed catalog search first and the user must review this result.
    if not settings.gemini_api_key:
        raise HTTPException(status_code=503, detail="Gemini is not configured")
    return ExerciseCandidate(status="needs_clarification")
