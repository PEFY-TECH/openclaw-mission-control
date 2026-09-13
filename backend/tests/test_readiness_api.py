from __future__ import annotations

import pytest
from fastapi import Response, status

from app import main as main_module
from app.core import readiness as readiness_module
from app.core.rate_limit_backend import RateLimitBackend
from app.core.readiness import ReadinessResult


@pytest.mark.asyncio
async def test_readyz_returns_ok_when_dependencies_are_ready(monkeypatch: pytest.MonkeyPatch) -> None:
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
async def test_readiness_skips_redis_for_memory_rate_limit(monkeypatch: pytest.MonkeyPatch) -> None:
    calls = {"redis": 0}

    async def _database_ready() -> bool:
        return True

    async def _redis_ready() -> bool:
        calls["redis"] += 1
        return False

    monkeypatch.setattr(readiness_module, "_database_ready", _database_ready)
    monkeypatch.setattr(readiness_module, "_rate_limit_redis_ready", _redis_ready)
    monkeypatch.setattr(readiness_module.settings, "rate_limit_backend", RateLimitBackend.MEMORY)

    result = await readiness_module.check_readiness()

    assert result.ok is True
    assert result.failed_dependencies == ()
    assert calls["redis"] == 0


@pytest.mark.asyncio
async def test_readiness_requires_redis_when_rate_limit_uses_redis(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    async def _database_ready() -> bool:
        return True

    async def _redis_ready() -> bool:
        return False

    monkeypatch.setattr(readiness_module, "_database_ready", _database_ready)
    monkeypatch.setattr(readiness_module, "_rate_limit_redis_ready", _redis_ready)
    monkeypatch.setattr(readiness_module.settings, "rate_limit_backend", RateLimitBackend.REDIS)

    result = await readiness_module.check_readiness()

    assert result.ok is False
    assert result.failed_dependencies == ("rate_limit_redis",)
