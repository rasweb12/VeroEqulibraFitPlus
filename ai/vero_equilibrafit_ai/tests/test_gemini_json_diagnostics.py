import asyncio
import logging
from types import SimpleNamespace
from unittest.mock import AsyncMock

from app.core.config import Settings
from app.providers.gemini_provider import GeminiProvider
from app.schemas.plans import PlanGenerateResponse


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


def test_structured_output_schema_is_forwarded_to_gemini():
    provider = GeminiProvider(Settings())
    generate = AsyncMock(return_value=SimpleNamespace(text="{}", candidates=[]))
    provider._client = SimpleNamespace(aio=SimpleNamespace(models=SimpleNamespace(generate_content=generate)))
    provider._types = SimpleNamespace(GenerateContentConfig=lambda **kwargs: kwargs)

    result = asyncio.run(provider.complete_json(system_prompt="", user_prompt="", response_schema=PlanGenerateResponse))

    assert result == {}
    assert generate.call_args.kwargs["config"]["response_schema"] is PlanGenerateResponse
    assert generate.call_args.kwargs["config"]["response_mime_type"] == "application/json"


def test_structured_sdk_payload_is_accepted_when_text_is_not_json():
    provider = GeminiProvider(Settings())
    response = SimpleNamespace(
        text="structured response",
        parsed={"targets": {"calories": 2000}},
        candidates=[],
    )
    provider._client = SimpleNamespace(
        aio=SimpleNamespace(models=SimpleNamespace(generate_content=AsyncMock(return_value=response)))
    )
    provider._types = SimpleNamespace(GenerateContentConfig=lambda **kwargs: kwargs)

    result = asyncio.run(provider.complete_json(system_prompt="", user_prompt="", response_schema=PlanGenerateResponse))

    assert result == {"targets": {"calories": 2000}}
