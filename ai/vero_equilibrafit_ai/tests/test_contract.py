from fastapi.testclient import TestClient
from app.main import app

def test_health_exposes_only_gemini_provider() -> None:
    response = TestClient(app).get("/health")
    assert response.status_code == 200
    assert response.json()["provider"] == "gemini"
