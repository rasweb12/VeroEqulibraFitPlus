import pytest
from pydantic import ValidationError

from app.core.config import Settings


def test_production_requires_internal_service_key() -> None:
    with pytest.raises(ValidationError, match="VERO_EQUILIBRAFIT_INTERNAL_API_KEY"):
        Settings(environment="Production", gemini_api_key="gemini-test-key")


def test_production_requires_gemini_key() -> None:
    with pytest.raises(ValidationError, match="VERO_EQUILIBRAFIT_GEMINI_API_KEY"):
        Settings(environment="Production", internal_api_key="internal-test-key")


def test_production_accepts_explicit_gemini_only_configuration() -> None:
    settings = Settings(
        environment="Production",
        internal_api_key="internal-test-key",
        gemini_api_key="gemini-test-key",
    )

    assert settings.provider == "gemini"
