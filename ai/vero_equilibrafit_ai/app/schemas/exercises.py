from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator


class ExerciseSuggestionRequest(BaseModel):
    query: str = Field(min_length=2, max_length=160)
    known_catalog_names: list[str] = Field(default_factory=list, max_length=20)


class ExerciseCandidate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    status: Literal["new_candidate", "needs_clarification"]
    existing_exercise_id: None = None
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
    def validate_candidate(self) -> ExerciseCandidate:
        if self.status == "new_candidate" and not self.name:
            raise ValueError("new_candidate requires a name")
        return self
