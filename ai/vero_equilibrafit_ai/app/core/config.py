from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import BaseModel, Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

AiProviderName = Literal["gemini"]


class AiCostPolicy(BaseModel):
    max_context_tokens: int = Field(default=6000, ge=1000, le=20000)
    max_retrieved_chunks: int = Field(default=4, ge=0, le=12)
    max_output_tokens: int = Field(default=1200, ge=200, le=4000)
    preferred_model: str = "gemini-3.5-flash-lite"
    preferred_provider: AiProviderName = "gemini"
    enable_rag: bool = True
    enable_memory: bool = True


class AiFeaturePolicy(BaseModel):
    primary: AiProviderName = "gemini"


class Settings(BaseSettings):
    """Configuration for the private, Gemini-only AI service."""

    model_config = SettingsConfigDict(env_prefix="VERO_EQUILIBRAFIT_", env_file=".env", extra="ignore")
    environment: str = "Development"
    log_level: str = "INFO"
    enable_docs: bool = False
    internal_api_key: str | None = None
    gemini_api_key: str | None = None
    gemini_model: str = "gemini-3.5-flash-lite"
    request_timeout_seconds: int = Field(default=30, ge=5, le=120)
    yolo_model_path: str | None = None
    default_language: str = "pt-BR"
    ai_max_context_tokens: int = Field(default=6000, ge=1000, le=20000)
    ai_max_retrieved_chunks: int = Field(default=4, ge=0, le=12)
    ai_max_output_tokens: int = Field(default=1200, ge=200, le=4000)
    ai_enable_rag: bool = True
    ai_enable_memory: bool = True

    @model_validator(mode="after")
    def validate_security(self) -> Settings:
        if self.environment.casefold() == "production" and not self.internal_api_key:
            raise ValueError("VERO_EQUILIBRAFIT_INTERNAL_API_KEY is required in Production.")
        return self

    @property
    def provider(self) -> AiProviderName:
        return "gemini"

    def model_for_provider(self, provider: AiProviderName = "gemini") -> str:
        return self.gemini_model

    def is_provider_configured(self, provider: AiProviderName = "gemini") -> bool:
        return bool(self.gemini_api_key)

    def provider_for_feature(self, feature: str) -> AiFeaturePolicy:
        return AiFeaturePolicy()

    @property
    def ai_cost_policy(self) -> AiCostPolicy:
        return AiCostPolicy(max_context_tokens=self.ai_max_context_tokens, max_retrieved_chunks=self.ai_max_retrieved_chunks, max_output_tokens=self.ai_max_output_tokens, preferred_model=self.gemini_model, enable_rag=self.ai_enable_rag, enable_memory=self.ai_enable_memory)


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
