"""
Pydantic models for API requests and responses
"""

from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict, Any, Literal
from datetime import datetime
from enum import Enum


# ==================== REQUEST MODELS ====================

class QueryRequest(BaseModel):
    """Main query request model"""
    
    query: str = Field(
        ...,
        min_length=3,
        max_length=500,
        description="User's agricultural query"
    )
    
    latitude: Optional[float] = Field(
        None,
        ge=-90,
        le=90,
        description="User's latitude for location-based data"
    )
    
    longitude: Optional[float] = Field(
        None,
        ge=-180,
        le=180,
        description="User's longitude for location-based data"
    )
    
    state: Optional[str] = Field(
        None,
        max_length=100,
        description="User's state (for regional data)"
    )
    
    district: Optional[str] = Field(
        None,
        max_length=100,
        description="User's district"
    )
    
    language: Optional[str] = Field(
        "en",
        description="Preferred response language (en, hi, etc.)"
    )
    
    user_id: Optional[str] = Field(
        None,
        description="User identifier for personalization"
    )
    
    context: Optional[Dict[str, Any]] = Field(
        None,
        description="Additional context (crop type, farm size, etc.)"
    )
    
    @validator('query')
    def validate_query(cls, v):
        """Validate query is not empty or just whitespace"""
        if not v or not v.strip():
            raise ValueError("Query cannot be empty")
        return v.strip()
    
    class Config:
        json_schema_extra = {
            "example": {
                "query": "What is the best time to plant wheat in my region?",
                "latitude": 28.7041,
                "longitude": 77.1025,
                "state": "Delhi",
                "district": "New Delhi",
                "language": "en"
            }
        }


class ImageAnalysisRequest(BaseModel):
    """Request for image-based analysis (plant disease detection)"""
    
    image_base64: str = Field(
        ...,
        description="Base64 encoded image"
    )
    
    query: Optional[str] = Field(
        None,
        description="Optional query about the image"
    )
    
    latitude: Optional[float] = None
    longitude: Optional[float] = None
