"""
Context Builder - Assembles context from multiple sources for LLM
"""

from typing import List, Dict, Any, Optional
from dataclasses import dataclass
from app.models.response_models import Source, IntentClassification
from app.utils.logger import setup_logging

logger = setup_logging()


@dataclass
class Context:
    """Context object with text and sources"""
    text: str
    sources: List[Source]
    metadata: Dict[str, Any]


class ContextBuilder:
    """Build context from retrieval results"""
    
    def __init__(self, max_context_length: int = 4000):
        self.max_context_length = max_context_length
    
    async def build(
        self,
        query: str,
        intent: IntentClassification,
        retrieval_results: List[Any],
        user_location: Optional[Dict] = None
    ) -> Context:
        """
        Build context from various sources
        
        Args:
            query: User query
            intent: Classified intent
            retrieval_results: Results from various retrieval sources
            user_location: User's location info
            
        Returns:
            Context object with assembled text and sources
        """
        sources = []
        context_parts = []
        
        # Add location context if available
        if user_location and user_location.get("latitude"):
            context_parts.append(
                f"User Location: {user_location.get('state', 'Unknown')}, "
                f"{user_location.get('district', 'Unknown')}"
            )
        
        # Process each retrieval result
        for result in retrieval_results:
            if isinstance(result, Exception):
                logger.warning(f"Retrieval error: {result}")
                continue
            
            if result is None:
                continue
            
            # Handle different result types
            if isinstance(result, list):
                # Vector search results
                for item in result[:3]:  # Limit to top 3
                    text = self._extract_text(item)
                    if text:
                        context_parts.append(text)
                        sources.append(Source(
                            type="knowledge_base",
                            title=item.get("metadata", {}).get("source", "Agricultural Knowledge"),
                            content=text[:200],
                            score=item.get("score")
                        ))
            
            elif isinstance(result, dict):
                # Structured data (weather, prices, etc.)
                if "current" in result or "forecast" in result:
                    # Weather data
                    weather_text = self._format_weather(result)
                    if weather_text:
                        context_parts.append(weather_text)
                        sources.append(Source(
                            type="weather_api",
                            title="Current Weather & Forecast",
                            content=result.get("summary", "")
                        ))
                
                elif "price" in result or "commodity" in result:
                    # Market price data
                    price_text = self._format_prices(result)
                    if price_text:
                        context_parts.append(price_text)
                        sources.append(Source(
                            type="market_data",
                            title="Market Prices",
                            content=price_text
                        ))
                
                elif "name" in result and "description" in result:
                    # Crop or scheme info
                    info_text = self._format_info(result)
                    if info_text:
                        context_parts.append(info_text)
                        sources.append(Source(
                            type="database",
                            title=result.get("name", "Information"),
                            content=info_text[:200]
                        ))
        
        # Combine context parts
        context_text = "\n\n".join(context_parts)
        
        # Truncate if too long
        if len(context_text) > self.max_context_length:
            context_text = context_text[:self.max_context_length] + "..."
            logger.info(f"Context truncated to {self.max_context_length} characters")
        
        logger.info(f"Built context: {len(context_text)} chars, {len(sources)} sources")
        
        return Context(
            text=context_text,
            sources=sources,
            metadata={
                "query": query,
                "intent": intent.primary_intent,
                "sources_count": len(sources),
                "context_length": len(context_text)
            }
        )
    
    def _extract_text(self, item: Dict) -> str:
        """Extract text from retrieval item"""
        if "text" in item:
            return item["text"]
        elif "content" in item:
            return item["content"]
        return ""
    
    def _format_weather(self, weather_data: Dict) -> str:
        """Format weather data as text"""
        parts = []
        
        current = weather_data.get("current", {})
        if current:
            parts.append(f"Current Weather: {current.get('weather_description', 'N/A')}")
            parts.append(f"Temperature: {current.get('temperature', 'N/A')}°C")
            parts.append(f"Humidity: {current.get('humidity', 'N/A')}%")
        
        forecast = weather_data.get("forecast", [])
        if forecast:
            parts.append("\nUpcoming Forecast:")
            for day in forecast[:3]:
                parts.append(
                    f"- {day.get('date', 'N/A')}: "
                    f"{day.get('weather_description', 'N/A')}, "
                    f"Max: {day.get('temperature_max', 'N/A')}°C, "
                    f"Rain: {day.get('precipitation', 0)}mm"
                )
        
        advisories = weather_data.get("agricultural_advisories", [])
        if advisories:
            parts.append("\nAgricultural Advisories:")
            for advisory in advisories:
                parts.append(f"- {advisory.get('message', '')}")
        
        return "\n".join(parts)
    
    def _format_prices(self, price_data: Dict) -> str:
        """Format price data as text"""
        if isinstance(price_data, list):
            parts = ["Market Prices:"]
            for item in price_data[:5]:
                parts.append(
                    f"- {item.get('commodity', 'N/A')}: "
                    f"₹{item.get('price', 'N/A')}/{item.get('unit', 'kg')} "
                    f"at {item.get('market', 'N/A')}"
                )
            return "\n".join(parts)
        else:
            return (
                f"Price of {price_data.get('commodity', 'N/A')}: "
                f"₹{price_data.get('price', 'N/A')}/{price_data.get('unit', 'kg')}"
            )
    
    def _format_info(self, info_data: Dict) -> str:
        """Format general information as text"""
        parts = []
        
        if "name" in info_data:
            parts.append(f"Name: {info_data['name']}")
        
        if "description" in info_data:
            parts.append(f"Description: {info_data['description']}")
        
        if "eligibility" in info_data:
            parts.append(f"Eligibility: {info_data['eligibility']}")
        
        if "benefit" in info_data:
            parts.append(f"Benefit: {info_data['benefit']}")
        
        # Add other relevant fields
        for key in ["soil_types", "water_requirement", "seasons", "growth_duration_days"]:
            if key in info_data:
                parts.append(f"{key.replace('_', ' ').title()}: {info_data[key]}")
        
        return "\n".join(parts)