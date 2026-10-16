from __future__ import annotations

import logging
import os
import re
from contextlib import asynccontextmanager
from time import perf_counter
from uuid import UUID, uuid4

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.api.v1.router import api_router
from app.core.config import get_settings
from app.core.logging import configure_logging, correlation_id


def create_app() -> FastAPI:
    settings = get_settings()
    configure_logging(settings.log_level)
    commit = os.getenv("RENDER_GIT_COMMIT", "")
    revision = commit[:12] if re.fullmatch(r"[0-9a-fA-F]{40,64}", commit) else "local"

    @asynccontextmanager
    async def lifespan(_: FastAPI):
        logging.getLogger(__name__).info("service.started provider=gemini model=%s", settings.gemini_model)
        yield
        logging.getLogger(__name__).info("service.stopped")

    app = FastAPI(
        lifespan=lifespan,
        title="VeroEqulibraFit+ AI",
        version="1.0.0",
        description="Internal Gemini-only gateway for Coach, workouts, meals, plans and labels.",
        docs_url="/docs" if settings.enable_docs else None,
        redoc_url=None,
    )

    @app.middleware("http")
    async def correlate(request: Request, call_next):
        try:
            identifier = str(UUID(request.headers.get("X-Correlation-ID", "")))
        except (ValueError, TypeError):
            identifier = str(uuid4())
        token = correlation_id.set(identifier)
        started = perf_counter()
        try:
            response = await call_next(request)
        except Exception as error:  # noqa: BLE001 -- final HTTP boundary; never expose upstream details
            logging.getLogger("requests").error("request.failed type=%s", type(error).__name__)
            response = JSONResponse(status_code=500, content={"code": "ai.internal_error", "correlation_id": identifier})
        finally:
            correlation_id.reset(token)
        response.headers["X-Correlation-ID"] = identifier
        logging.getLogger("requests").info("request.completed path=%s status=%s duration_ms=%s", request.url.path, response.status_code, round((perf_counter() - started) * 1000, 2))
        return response

    def health_payload() -> dict[str, str]:
        return {"status": "healthy", "service": "vero-equilibrafit-ai", "revision": revision, "provider": "gemini", "model": settings.gemini_model}

    @app.get("/health", tags=["system"])
    async def health() -> dict[str, str]:
        """Compatibility endpoint for existing Render configuration."""
        return health_payload()

    @app.get("/health/live", tags=["system"])
    async def liveness() -> dict[str, str]:
        """Reports only that the FastAPI process is running."""
        return health_payload()

    @app.get("/health/ready", tags=["system"])
    async def readiness() -> dict[str, str]:
        """Reports startup configuration readiness, not a live Gemini request."""
        return health_payload()

    app.include_router(api_router)
    return app


app = create_app()
