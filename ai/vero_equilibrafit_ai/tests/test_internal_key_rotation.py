import asyncio

import pytest
from fastapi import HTTPException

from app.api.dependencies import require_internal_api_key
from app.core.config import Settings


def _with_settings(monkeypatch: pytest.MonkeyPatch, settings: Settings) -> None:
    monkeypatch.setattr("app.api.dependencies.get_settings", lambda: settings)


def test_accepts_current_key_during_rotation(monkeypatch: pytest.MonkeyPatch) -> None:
    _with_settings(
        monkeypatch,
        Settings(internal_api_key="new-key", previous_internal_api_key="old-key"),
    )
    asyncio.run(require_internal_api_key("new-key"))


def test_accepts_previous_key_only_during_rotation(monkeypatch: pytest.MonkeyPatch) -> None:
    _with_settings(
        monkeypatch,
        Settings(internal_api_key="new-key", previous_internal_api_key="old-key"),
    )
    asyncio.run(require_internal_api_key("old-key"))


@pytest.mark.parametrize("candidate", [None, "", "wrong-key", "chave-inválida-á"])
def test_rejects_unknown_key(monkeypatch: pytest.MonkeyPatch, candidate: str | None) -> None:
    _with_settings(
        monkeypatch,
        Settings(internal_api_key="new-key", previous_internal_api_key="old-key"),
    )
    with pytest.raises(HTTPException) as error:
        asyncio.run(require_internal_api_key(candidate))
    assert error.value.status_code == 401


def test_does_not_accept_retired_key_when_previous_is_unset(monkeypatch: pytest.MonkeyPatch) -> None:
    _with_settings(monkeypatch, Settings(internal_api_key="new-key"))
    with pytest.raises(HTTPException) as error:
        asyncio.run(require_internal_api_key("old-key"))
    assert error.value.status_code == 401
