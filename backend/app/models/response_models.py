"""
Pydantic models for API requests and responses
"""

from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict, Any, Literal
from datetime import datetime
from enum import Enum
# ==================== RESPONSE MODELS ====================

class IntentType(str, Enum):
    """Types of query intents"""
    CROP_CULTIVATION = "crop_cultivation"
    PEST_MANAGEMENT = "pest_management"
    WEATHER_QUERY = "weather_query"
    MARKET_PRICES = "market_prices"
    GOVERNMENT_SCHEMES = "government_schemes"
    SOIL_HEALTH = "soil_health"
    GENERAL = "general"


class Source(BaseModel):
    """Source attribution for response"""
    
    type: str = Field(
        ...,
        description="Source type (knowledge_base, weather_api, etc.)"
    )
    
    title: str = Field(
        ...,
        description="Source title or name"
    )
    
    content: Optional[str] = Field(
        None,
        description="Relevant excerpt from source"
    )
    
    url: Optional[str] = Field(
        None,
        description="URL if available"
    )
    
    score: Optional[float] = Field(
        None,
        ge=0,
        le=1,
        description="Relevance score"
    )
    
    metadata: Optional[Dict[str, Any]] = Field(
        default_factory=dict,
        description="Additional metadata"
    )


class QueryResponse(BaseModel):
    """Main query response model"""
    
    query_id: str = Field(
        ...,
        description="Unique identifier for this query"
    )
    
    query: str = Field(
        ...,
        description="Original query text"
    )
    
    answer: str = Field(
        ...,
        description="Generated answer"
    )
    
    sources: List[Source] = Field(
        default_factory=list,
        description="Sources used to generate answer"
    )
    
    intent: str = Field(
        ...,
        description="Detected query intent"
    )
    
    confidence: float = Field(
        ...,
        ge=0,
        le=1,
        description="Confidence score for the answer"
    )
    
    metadata: Dict[str, Any] = Field(
        default_factory=dict,
        description="Additional metadata"
    )
    
    cached: bool = Field(
        False,
        description="Whether response was served from cache"
    )
    
    timestamp: datetime = Field(
        default_factory=datetime.now,
        description="Response timestamp"
    )
    
    class Config:
        json_schema_extra = {
            "example": {
                "query_id": "q_1234567890",
                "query": "What is the best time to plant wheat?",
                "answer": "The best time to plant wheat in North India is from late October to early November (mid to late Rabi season). This timing ensures the crop gets optimal temperature conditions during the growing season...",
                "sources": [
                    {
                        "type": "knowledge_base",
                        "title": "Wheat Cultivation Guide",
                        "score": 0.89
                    },
                    {
                        "type": "weather_api",
                        "title": "Current Weather Forecast",
                        "score": 0.76
                    }
                ],
                "intent": "crop_cultivation",
                "confidence": 0.92,
                "metadata": {
                    "processing_time_seconds": 1.34,
                    "sources_used": 2
                },
                "cached": False,
                "timestamp": "2024-11-18T10:30:00"
            }
        }


class ErrorResponse(BaseModel):
    """Error response model"""
    
    success: Literal[False] = False
    error: str = Field(..., description="Error type")
    message: str = Field(..., description="Error message")
    query_id: Optional[str] = Field(None, description="Query ID if available")
    timestamp: datetime = Field(default_factory=datetime.now)


class HealthResponse(BaseModel):
    """Health check response"""
    
    status: str = Field(..., description="Service status")
    version: str = Field(..., description="API version")
    environment: str = Field(..., description="Environment")
    timestamp: datetime = Field(default_factory=datetime.now)
    
    services: Dict[str, bool] = Field(
        default_factory=dict,
        description="Status of dependent services"
    )


class IntentClassification(BaseModel):
    """Intent classification result"""
    
    primary_intent: str
    confidence: float
    requires_crop_data: bool = False
    requires_market_data: bool = False
    requires_scheme_info: bool = False
    extracted_entities: Dict[str, str] = Field(default_factory=dict)


class WeatherData(BaseModel):
    """Weather data model"""
    
    location: Dict[str, Any]
    current: Dict[str, Any]
    forecast: List[Dict[str, Any]]
    agricultural_advisories: List[Dict[str, Any]]
    summary: str


class MarketPrice(BaseModel):
    """Market price data"""
    
    commodity: str
    price: float
    unit: str
    market: str
    date: str
    state: Optional[str] = None


class GovernmentScheme(BaseModel):
    """Government scheme information"""
    
    id: str
    name: str
    description: str
    eligibility: str
    benefit: str
    application_url: Optional[str] = None
    contact_info: Optional[str] = None