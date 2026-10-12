import asyncio
import json
import logging
from functools import lru_cache
from typing import Literal

from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel, Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="VERO_EQUILIBRAFIT_", extra="ignore")
    environment: str = "development"
    internal_api_key: str = ""
    gemini_api_key: str = ""
    gemini_model: str = "gemini-3.5-flash-lite"
    request_timeout_seconds: int = Field(default=30, ge=5, le=120)
    max_output_tokens: int = Field(default=1200, ge=200, le=4000)

    @model_validator(mode="after")
    def validate_production_key(self) -> "Settings":
        if self.environment.casefold() == "production" and not self.internal_api_key:
            raise ValueError("VERO_EQUILIBRAFIT_INTERNAL_API_KEY is required in production")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()


class ExerciseSuggestionRequest(BaseModel):
    query: str = Field(min_length=2, max_length=160)
    known_catalog_names: list[str] = Field(default_factory=list, max_length=20)


class ExerciseCandidate(BaseModel):
    status: Literal["existing_match", "new_candidate", "needs_clarification"]
    existing_exercise_id: str | None = None
    name: str | None = Field(default=None, max_length=160)
    aliases: list[str] = Field(default_factory=list, max_length=12)
    primary_muscle: str | None = Field(default=None, max_length=80)
    secondary_muscles: list[str] = Field(default_factory=list, max_length=8)
    equipment: str | None = Field(default=None, max_length=120)
    difficulty: Literal["Iniciante", "Intermediário", "Avançado"] | None = None
    instructions: list[str] = Field(default_factory=list, max_length=10)
    common_errors: list[str] = Field(default_factory=list, max_length=8)
    safety_tips: list[str] = Field(default_factory=list, max_length=8)
    alternatives: list[str] = Field(default_factory=list, max_length=8)
    requires_user_confirmation: Literal[True] = True

    @model_validator(mode="after")
    def validate_status(self) -> "ExerciseCandidate":
        if self.status == "existing_match" and not self.existing_exercise_id:
            raise ValueError("existing_match requires an existing exercise ID")
        if self.status == "new_candidate" and not self.name:
            raise ValueError("new_candidate requires a name")
        if self.status != "existing_match" and self.existing_exercise_id is not None:
            raise ValueError("new candidates must not contain an existing exercise ID")
        return self


class GeminiExerciseService:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    async def suggest(self, request: ExerciseSuggestionRequest) -> ExerciseCandidate:
        if not self._settings.gemini_api_key:
            raise HTTPException(status_code=503, detail="Gemini is not configured")
        try:
            from google import genai
            from google.genai import types

            client = genai.Client(api_key=self._settings.gemini_api_key, http_options=types.HttpOptions(timeout=self._settings.request_timeout_seconds * 1000))
            prompt = (
                "Sugira um exercício fitness em JSON. Não invente IDs de catálogo, não prometa mídia, "
                "não atribua cargas pessoais. Se faltar contexto, use needs_clarification. "
                f"Consulta: {request.query}. Nomes já conhecidos: {json.dumps(request.known_catalog_names, ensure_ascii=False)}."
            )
            response = await asyncio.wait_for(
                client.aio.models.generate_content(
                    model=self._settings.gemini_model,
                    contents=prompt,
                    config=types.GenerateContentConfig(response_mime_type="application/json", temperature=0.2, max_output_tokens=self._settings.max_output_tokens),
                ),
                timeout=self._settings.request_timeout_seconds,
            )
            payload = json.loads((response.text or "").strip())
            candidate = ExerciseCandidate.model_validate(payload)
            if candidate.status == "existing_match":
                raise HTTPException(status_code=422, detail="Gemini cannot establish existing catalog IDs")
            return candidate
        except HTTPException:
            raise
        except asyncio.TimeoutError:
            raise HTTPException(status_code=504, detail="Gemini timed out") from None
        except (ValueError, json.JSONDecodeError):
            raise HTTPException(status_code=502, detail="Gemini returned an invalid structured response") from None
        except Exception:
            logger.warning("gemini.exercise_suggestion_failed", exc_info=False)
            raise HTTPException(status_code=502, detail="Gemini is temporarily unavailable") from None


def require_internal_key(settings: Settings = Depends(get_settings), x_internal_api_key: str | None = Header(default=None)) -> None:
    if settings.internal_api_key and x_internal_api_key == settings.internal_api_key:
        return
    raise HTTPException(status_code=401, detail="internal authentication required")


app = FastAPI(title="VeroEqulibraFit+ AI", docs_url=None, redoc_url=None)


@app.get("/health")
async def health(settings: Settings = Depends(get_settings)) -> dict[str, str]:
    return {"status": "healthy", "provider": "gemini", "model": settings.gemini_model}


@app.post("/internal/v1/exercises/suggest", response_model=ExerciseCandidate, dependencies=[Depends(require_internal_key)])
async def suggest_exercise(request: ExerciseSuggestionRequest, settings: Settings = Depends(get_settings)) -> ExerciseCandidate:
    return await GeminiExerciseService(settings).suggest(request)
