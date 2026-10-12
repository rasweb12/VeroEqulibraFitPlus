import pytest
from pydantic import ValidationError
from app.main import ExerciseCandidate


def test_new_candidate_requires_user_confirmation() -> None:
    candidate = ExerciseCandidate(status="new_candidate", name="Supino inclinado articulado")
    assert candidate.requires_user_confirmation is True
    assert candidate.existing_exercise_id is None


def test_existing_match_without_identifier_is_rejected() -> None:
    with pytest.raises(ValidationError):
        ExerciseCandidate(status="existing_match")


def test_new_candidate_cannot_carry_a_catalog_identifier() -> None:
    with pytest.raises(ValidationError):
        ExerciseCandidate(status="new_candidate", name="Novo", existing_exercise_id="squat")
