from __future__ import annotations

from fastapi import Header, HTTPException, status

from app.core.config import get_settings


async def require_internal_api_key(
    x_internal_api_key: str | None = Header(default=None, alias="X-Internal-Api-Key"),
) -> None:
    """Accept calls only from the authenticated .NET API service."""
    settings = get_settings()
    if not settings.internal_api_key or x_internal_api_key != settings.internal_api_key:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Internal authentication required.")
