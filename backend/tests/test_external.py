# tests/test_external.py
from app.services.external.weather import get_weather

def test_weather():
    data = get_weather(22.7, 75.8)
    assert data["temperature"] is not None
