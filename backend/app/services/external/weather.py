"""Weather Service - direct Open-Meteo HTTP calls (no wrapper)"""

import aiohttp
import asyncio
from typing import Dict, Optional
from app.config import settings
from app.utils.logger import setup_logging

logger = setup_logging()

class WeatherService:
    def __init__(self):
        self.base_url = settings.WEATHER_API_URL.rstrip("/") if hasattr(settings, "WEATHER_API_URL") else "https://api.open-meteo.com/v1/forecast"
        self.session: Optional[aiohttp.ClientSession] = None
        self.timeout = aiohttp.ClientTimeout(total=15)

    async def _get_session(self) -> aiohttp.ClientSession:
        if self.session is None or self.session.closed:
            self.session = aiohttp.ClientSession(timeout=self.timeout)
        return self.session

    async def close(self):
        if self.session and not self.session.closed:
            await self.session.close()

    async def get_forecast(self, latitude: float, longitude: float, days: int = 7) -> Dict:
        try:
            session = await self._get_session()
            params = {
                "latitude": latitude,
                "longitude": longitude,
                "current_weather": "true",
                "timezone": "Asia/Kolkata",
                "daily": ",".join([
                    "temperature_2m_max","temperature_2m_min","precipitation_sum",
                    "precipitation_probability_max","weathercode","windspeed_10m_max",
                    "sunrise","sunset"
                ])
            }
            async with session.get(self.base_url, params=params) as resp:
                # some Open-Meteo endpoints expect /forecast path; accept both
                if resp.status == 404:
                    async with session.get(f"{self.base_url}/forecast", params=params) as resp2:
                        if resp2.status != 200:
                            logger.error(f"Weather API error {resp2.status}")
                            return self._get_fallback_data()
                        data = await resp2.json()
                else:
                    if resp.status != 200:
                        text = await resp.text()
                        logger.error(f"Weather API error {resp.status}: {text}")
                        return self._get_fallback_data()
                    data = await resp.json()

            processed = self._process_weather_data(data, days)
            return processed

        except asyncio.TimeoutError:
            logger.error("Weather API timeout")
            return self._get_fallback_data()
        except Exception as e:
            logger.error(f"Weather API error: {e}", exc_info=True)
            return self._get_fallback_data()

    def _process_weather_data(self, raw: Dict, days: int) -> Dict:
        current = raw.get("current_weather", {}) or raw.get("current", {})
        daily = raw.get("daily", {})
        advisories = []
        temp = current.get("temperature") or current.get("temperature_2m") or None
        if temp is not None:
            try:
                temp_val = float(temp)
            except Exception:
                temp_val = None
            if temp_val is not None:
                if temp_val > 35:
                    advisories.append({"type":"heat_stress","severity":"high","message":"High temp - irrigate."})
                if temp_val < 8:
                    advisories.append({"type":"cold_stress","severity":"medium","message":"Low temp - protect crops."})
        forecast = []
        times = daily.get("time", [])
        for i, date in enumerate(times[:days]):
            forecast.append({
                "date": date,
                "temperature_max": (daily.get("temperature_2m_max") or [None])[i] if i < len(daily.get("temperature_2m_max", [])) else None,
                "temperature_min": (daily.get("temperature_2m_min") or [None])[i] if i < len(daily.get("temperature_2m_min", [])) else None,
                "precipitation": (daily.get("precipitation_sum") or [None])[i] if i < len(daily.get("precipitation_sum", [])) else None,
                "precipitation_probability": (daily.get("precipitation_probability_max") or [None])[i] if i < len(daily.get("precipitation_probability_max", [])) else None,
                "weather_code": (daily.get("weathercode") or [None])[i] if i < len(daily.get("weathercode", [])) else None,
            })
        summary = f"Current: temp {temp}°C. {len(advisories)} advisory(ies) in effect." if temp is not None else "Current conditions unavailable"
        return {
            "location": {"latitude": raw.get("latitude"), "longitude": raw.get("longitude"), "timezone": raw.get("timezone")},
            "current": {
                "temperature": temp,
                "wind_speed": current.get("windspeed") or current.get("wind_speed"),
                "weather_description": self._get_weather_description(current.get("weathercode") or current.get("weather_code"))
            },
            "forecast": forecast,
            "agricultural_advisories": advisories,
            "summary": summary
        }

    def _get_weather_description(self, code: Optional[int]) -> str:
        mapping = {
            0:"Clear sky",1:"Mainly clear",2:"Partly cloudy",3:"Overcast",
            45:"Fog",48:"Depositing rime fog",51:"Light drizzle",53:"Moderate drizzle",
            55:"Dense drizzle",61:"Slight rain",63:"Moderate rain",65:"Heavy rain",
            71:"Slight snow",73:"Moderate snow",75:"Heavy snow",77:"Snow grains",
            80:"Slight rain showers",81:"Moderate rain showers",82:"Violent rain showers",
            95:"Thunderstorm"
        }
        return mapping.get(code, "Unknown")

    def _get_fallback_data(self) -> Dict:
        return {"location":{}, "current":{}, "forecast":[],"agricultural_advisories":[],"summary":"Weather data temporarily unavailable."}

weather_service = WeatherService()
