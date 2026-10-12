import pytest
from pydantic import ValidationError

from app.schemas.exercises import ExerciseCandidate


def test_new_candidate_requires_user_confirmation() -> None:
    candidate = ExerciseCandidate(status="new_candidate", name="Supino inclinado articulado")
    assert candidate.requires_user_confirmation is True
    assert candidate.existing_exercise_id is None


def test_existing_catalog_identifiers_are_rejected_from_gemini_responses() -> None:
    with pytest.raises(ValidationError):
        ExerciseCandidate(status="new_candidate", name="Supino", existing_exercise_id="catalog-1")


def test_existing_match_is_not_an_ai_output_status() -> None:
    with pytest.raises(ValidationError):
        ExerciseCandidate(status="existing_match", name="Novo")
