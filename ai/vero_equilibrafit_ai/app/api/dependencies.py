from __future__ import annotations

from secrets import compare_digest

from fastapi import Header, HTTPException, status

from app.core.config import get_settings


async def require_internal_api_key(
    x_internal_api_key: str | None = Header(default=None, alias="X-Internal-Api-Key"),
) -> None:
    """Accept calls only from the authenticated .NET API service."""
    settings = get_settings()
    accepted_keys = (
        settings.internal_api_key,
        settings.previous_internal_api_key,
    )
    candidate = x_internal_api_key.encode("utf-8") if x_internal_api_key else None
    if not candidate or not any(
        key and compare_digest(candidate, key.encode("utf-8")) for key in accepted_keys
    ):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Internal authentication required.")
