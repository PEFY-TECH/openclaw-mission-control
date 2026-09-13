"""Dependency-aware readiness checks for production orchestration."""

from __future__ import annotations

import asyncio
from dataclasses import dataclass
from typing import Awaitable, cast

import redis.asyncio as aioredis
from sqlalchemy import text

from app.core.config import settings
from app.core.logging import get_logger
from app.core.rate_limit_backend import RateLimitBackend
from app.db.session import async_engine

logger = get_logger(__name__)
READINESS_IO_TIMEOUT_SECONDS = 2.0


@dataclass(frozen=True, slots=True)
class ReadinessResult:
    """Internal readiness result without exposing connection details or secrets."""

    ok: bool
    failed_dependencies: tuple[str, ...] = ()


async def _database_ready() -> bool:
    """Return whether the primary database accepts a bounded minimal query."""
    try:
        async with asyncio.timeout(READINESS_IO_TIMEOUT_SECONDS):
            async with async_engine.connect() as connection:
                await connection.execute(text("SELECT 1"))
    except TimeoutError:
        logger.warning("readiness.database.timeout")
        return False
    except Exception:
        logger.warning("readiness.database.unavailable", exc_info=True)
        return False
    return True


async def _redis_ready(url: str, dependency: str) -> bool:
    """Return whether one configured Redis dependency responds within the readiness deadline."""
    client = aioredis.from_url(url)
    try:
        async with asyncio.timeout(READINESS_IO_TIMEOUT_SECONDS):
            pong = await cast(Awaitable[object], client.ping())
        return bool(pong)
    except TimeoutError:
        logger.warning("readiness.%s.timeout", dependency)
        return False
    except Exception:
        logger.warning("readiness.%s.unavailable", dependency, exc_info=True)
        return False
    finally:
        try:
            await client.aclose()
        except Exception:
            logger.warning("readiness.%s.close_failed", dependency, exc_info=True)


async def check_readiness() -> ReadinessResult:
    """Check the critical dependencies required to safely serve orchestration traffic.

    PostgreSQL and the RQ Redis queue are always required by the application.
    Rate-limit Redis is additionally required when Redis-backed rate limiting is configured.
    All probes execute concurrently and each has a server-side deadline shorter than the
    platform HTTP health-check timeout.
    """
    checks: list[tuple[str, Awaitable[bool]]] = [
        ("database", _database_ready()),
        ("rq_redis", _redis_ready(settings.rq_redis_url, "rq_redis")),
    ]

    if settings.rate_limit_backend == RateLimitBackend.REDIS:
        checks.append(
            (
                "rate_limit_redis",
                _redis_ready(settings.rate_limit_redis_url, "rate_limit_redis"),
            )
        )

    results = await asyncio.gather(*(probe for _, probe in checks))
    failed = tuple(
        dependency
        for (dependency, _), is_ready in zip(checks, results, strict=True)
        if not is_ready
    )
    return ReadinessResult(ok=not failed, failed_dependencies=failed)
