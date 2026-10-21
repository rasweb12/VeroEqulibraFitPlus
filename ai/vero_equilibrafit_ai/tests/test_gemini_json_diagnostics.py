import asyncio
import logging
from types import SimpleNamespace
from unittest.mock import AsyncMock

from app.core.config import Settings
from app.providers.gemini_provider import GeminiProvider


def test_invalid_json_logs_only_category_and_finish_reason(caplog):
    provider = GeminiProvider(Settings())
    response = SimpleNamespace(
        text='{"private": "sensitive',
        candidates=[SimpleNamespace(finish_reason=SimpleNamespace(name="MAX_TOKENS"))],
    )
    provider._client = SimpleNamespace(
        aio=SimpleNamespace(models=SimpleNamespace(generate_content=AsyncMock(return_value=response)))
    )
    provider._types = SimpleNamespace(GenerateContentConfig=lambda **kwargs: kwargs)

    with caplog.at_level(logging.WARNING):
        result = asyncio.run(provider.complete_json(system_prompt="private prompt", user_prompt="private user"))

    assert result is None
    assert "category=invalid_json_or_non_object finish_reason=MAX_TOKENS" in caplog.text
    assert "sensitive" not in caplog.text
    assert "private prompt" not in caplog.text
    assert "private user" not in caplog.text


def test_empty_json_response_does_not_log_untrusted_finish_reason(caplog):
    provider = GeminiProvider(Settings())
    response = SimpleNamespace(text=None, candidates=[SimpleNamespace(finish_reason=SimpleNamespace(name="private"))])
    provider._client = SimpleNamespace(
        aio=SimpleNamespace(models=SimpleNamespace(generate_content=AsyncMock(return_value=response)))
    )
    provider._types = SimpleNamespace(GenerateContentConfig=lambda **kwargs: kwargs)

    with caplog.at_level(logging.WARNING):
        result = asyncio.run(provider.complete_json(system_prompt="", user_prompt=""))

    assert result is None
    assert "category=empty finish_reason=UNKNOWN" in caplog.text
    assert "private" not in caplog.text

