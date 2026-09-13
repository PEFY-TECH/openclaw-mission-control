"""Dependency-aware readiness checks for production orchestration."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Awaitable, cast

import redis.asyncio as aioredis
from sqlalchemy import text

from app.core.config import settings
from app.core.logging import get_logger
from app.core.rate_limit_backend import RateLimitBackend
from app.db.session import async_engine

logger = get_logger(__name__)


@dataclass(frozen=True, slots=True)
class ReadinessResult:
    """Internal readiness result without exposing connection details or secrets."""

    ok: bool
    failed_dependencies: tuple[str, ...] = ()


async def _database_ready() -> bool:
    """Return whether the primary database accepts a minimal query."""
    try:
        async with async_engine.connect() as connection:
            await connection.execute(text("SELECT 1"))
    except Exception:
        logger.warning("readiness.database.unavailable", exc_info=True)
        return False
    return True


async def _rate_limit_redis_ready() -> bool:
    """Return whether Redis is reachable when it is a configured critical dependency."""
    client = aioredis.from_url(settings.rate_limit_redis_url)
    try:
        pong = await cast(Awaitable[object], client.ping())
        return bool(pong)
    except Exception:
        logger.warning("readiness.rate_limit_redis.unavailable", exc_info=True)
        return False
    finally:
        await client.aclose()


async def check_readiness() -> ReadinessResult:
    """Check critical dependencies required for this backend to safely serve traffic.

    PostgreSQL is always required. Redis is required by this probe only when the
    configured rate-limit backend uses Redis; memory-backed development remains
    independent from Redis.
    """
    failed: list[str] = []

    if not await _database_ready():
        failed.append("database")

    if settings.rate_limit_backend == RateLimitBackend.REDIS:
        if not await _rate_limit_redis_ready():
            failed.append("rate_limit_redis")

    return ReadinessResult(ok=not failed, failed_dependencies=tuple(failed))
