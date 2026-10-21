import asyncio
import logging
from unittest.mock import AsyncMock

from app.core.config import Settings
from app.providers.ai_provider_router import AiProviderResult
from app.schemas.plans import PlanGenerateRequest
from app.services.plan_service import PlanService


def test_plan_fallback_logs_provider_category_without_request_data(caplog):
    service = PlanService(Settings())
    service._provider.complete_json_result = AsyncMock(
        return_value=AiProviderResult(error_type="invalid_response")
    )
    request = PlanGenerateRequest(objective="private objective")

    with caplog.at_level(logging.WARNING):
        result = asyncio.run(service.generate(request))

    assert result.fallback_used
    assert "stage=provider category=invalid_response" in caplog.text
    assert "private objective" not in caplog.text


def test_plan_fallback_logs_schema_failure_without_model_output(caplog):
    service = PlanService(Settings())
    service._provider.complete_json_result = AsyncMock(
        return_value=AiProviderResult(payload={"private_data": "sensitive output"})
    )

    with caplog.at_level(logging.WARNING):
        result = asyncio.run(service.generate(PlanGenerateRequest(objective="private objective")))

    assert result.fallback_used
    assert "stage=schema_validation" in caplog.text
    assert "sensitive output" not in caplog.text
    assert "private objective" not in caplog.text
