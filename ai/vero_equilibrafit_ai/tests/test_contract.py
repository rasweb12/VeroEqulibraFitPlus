from fastapi.testclient import TestClient

from app.main import app


def test_health_exposes_only_gemini_provider() -> None:
    response = TestClient(app).get("/health")
    assert response.status_code == 200
    assert response.json()["provider"] == "gemini"


def test_private_ai_routes_require_the_internal_service_key() -> None:
    response = TestClient(app).post(
        "/api/v1/coach/chat",
        json={"mensagem": "Como organizar meu treino hoje?"},
    )
    assert response.status_code == 401
