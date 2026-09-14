from __future__ import annotations

import asyncio

import pytest
from fastapi import Response, status

from app import main as main_module
from app.core import readiness as readiness_module
from app.core.rate_limit_backend import RateLimitBackend
from app.core.readiness import ReadinessResult


@pytest.mark.asyncio
async def test_readyz_returns_ok_when_dependencies_are_ready(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    async def _ready() -> ReadinessResult:
        return ReadinessResult(ok=True)

    monkeypatch.setattr(main_module, "check_readiness", _ready)
    response = Response()

    payload = await main_module.readyz(response)

    assert payload.ok is True
    assert response.status_code == status.HTTP_200_OK


@pytest.mark.asyncio
async def test_readyz_returns_503_without_exposing_dependency_details(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    async def _not_ready() -> ReadinessResult:
        return ReadinessResult(ok=False, failed_dependencies=("database",))

    monkeypatch.setattr(main_module, "check_readiness", _not_ready)
    response = Response()

    payload = await main_module.readyz(response)

    assert payload.ok is False
    assert response.status_code == status.HTTP_503_SERVICE_UNAVAILABLE
    assert payload.model_dump() == {"ok": False}


@pytest.mark.asyncio
async def test_readiness_requires_rq_redis_even_with_memory_rate_limit(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    calls: list[tuple[str, str]] = []

    async def _database_ready() -> bool:
        return True

    async def _redis_ready(url: str, dependency: str) -> bool:
        calls.append((url, dependency))
        return dependency == "rq_redis"

    monkeypatch.setattr(readiness_module, "_database_ready", _database_ready)
    monkeypatch.setattr(readiness_module, "_redis_ready", _redis_ready)
    monkeypatch.setattr(readiness_module.settings, "rate_limit_backend", RateLimitBackend.MEMORY)
    monkeypatch.setattr(readiness_module.settings, "rq_redis_url", "redis://queue.test/0")

    result = await readiness_module.check_readiness()

    assert result.ok is True
    assert result.failed_dependencies == ()
    assert calls == [("redis://queue.test/0", "rq_redis")]


@pytest.mark.asyncio
async def test_readiness_fails_when_rq_redis_is_unavailable(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    async def _database_ready() -> bool:
        return True

    async def _redis_ready(url: str, dependency: str) -> bool:
        del url
        return dependency != "rq_redis"

    monkeypatch.setattr(readiness_module, "_database_ready", _database_ready)
    monkeypatch.setattr(readiness_module, "_redis_ready", _redis_ready)
    monkeypatch.setattr(readiness_module.settings, "rate_limit_backend", RateLimitBackend.MEMORY)

    result = await readiness_module.check_readiness()

    assert result.ok is False
    assert result.failed_dependencies == ("rq_redis",)


@pytest.mark.asyncio
async def test_readiness_requires_rate_limit_redis_when_configured(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    calls: list[str] = []

    async def _database_ready() -> bool:
        return True

    async def _redis_ready(url: str, dependency: str) -> bool:
        del url
        calls.append(dependency)
        return dependency == "rq_redis"

    monkeypatch.setattr(readiness_module, "_database_ready", _database_ready)
    monkeypatch.setattr(readiness_module, "_redis_ready", _redis_ready)
    monkeypatch.setattr(readiness_module.settings, "rate_limit_backend", RateLimitBackend.REDIS)
    monkeypatch.setattr(readiness_module.settings, "rq_redis_url", "redis://queue.test/0")
    monkeypatch.setattr(readiness_module.settings, "rate_limit_redis_url", "redis://rate.test/1")

    result = await readiness_module.check_readiness()

    assert result.ok is False
    assert result.failed_dependencies == ("rate_limit_redis",)
    assert calls == ["rq_redis", "rate_limit_redis"]


@pytest.mark.asyncio
async def test_redis_readiness_timeout_is_bounded(monkeypatch: pytest.MonkeyPatch) -> None:
    closed = False

    class FakeRedis:
        async def ping(self) -> bool:
            await asyncio.sleep(0.05)
            return True

        async def aclose(self) -> None:
            nonlocal closed
            closed = True

    monkeypatch.setattr(readiness_module.aioredis, "from_url", lambda _: FakeRedis())
    monkeypatch.setattr(readiness_module, "READINESS_IO_TIMEOUT_SECONDS", 0.001)

    result = await readiness_module._redis_ready("redis://example.invalid/0", "rq_redis")

    assert result is False
    assert closed is True
