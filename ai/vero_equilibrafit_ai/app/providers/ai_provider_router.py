from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from app.core.config import Settings
from app.providers.gemini_provider import GeminiProvider
from app.providers.provider_errors import AiProviderError


@dataclass(frozen=True)
class AiProviderResult:
    payload: Any = None
    provider: str | None = None
    model: str | None = None
    fallback_used: bool = False
    error_type: str | None = None
    upstream_status_code: int | None = None


class AiProviderRouter:
    """Gemini-only boundary used by every AI feature service."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._provider = GeminiProvider(settings)

    async def _execute(self, method: str, **kwargs: Any) -> AiProviderResult:
        if not self._provider.is_configured:
            return AiProviderResult(error_type="unconfigured")
        try:
            payload = await getattr(self._provider, method)(model=self._settings.gemini_model, **kwargs)
        except AiProviderError as error:
            return AiProviderResult(error_type=error.error_type, upstream_status_code=error.upstream_status_code)
        if (isinstance(payload, str) and payload.strip()) or isinstance(payload, dict):
            return AiProviderResult(payload=payload, provider="gemini", model=self._settings.gemini_model)
        return AiProviderResult(error_type="invalid_response")

    async def complete_result(self, **kwargs: Any) -> AiProviderResult:
        kwargs.pop("feature", None)
        kwargs.pop("provider", None)
        return await self._execute("complete", **kwargs)

    async def complete_json_result(self, **kwargs: Any) -> AiProviderResult:
        kwargs.pop("feature", None)
        return await self._execute("complete_json", **kwargs)

    async def analyze_image_json_result(self, **kwargs: Any) -> AiProviderResult:
        kwargs.pop("feature", None)
        return await self._execute("analyze_image_json", **kwargs)
