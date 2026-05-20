"""
Configuration Management
Loads settings from environment variables with defaults
"""

from pydantic_settings import BaseSettings
from typing import Optional
import os


class Settings(BaseSettings):
    """Application settings"""
    
    # Application
    APP_NAME: str = "Virtual Krishi Officer API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    ENVIRONMENT: str = "development"
    
    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    WORKERS: int = 2
    
    # Database
    DATABASE_URL: str = "sqlite:///./app/data/agri_advisory.db"
    
    # Redis Cache
    REDIS_URL: Optional[str] = None
    CACHE_TTL: int = 3600  # 1 hour
    ENABLE_CACHE: bool = True
    
    # External APIs
    WEATHER_API_URL: str = "https://api.open-meteo.com/v1/forecast"
    AGMARKNET_BASE_URL: str = "https://agmarknet.gov.in"
    
    # LLM Configuration
    OLLAMA_HOST: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "mistral:7b"
    LLM_TEMPERATURE: float = 0.7
    LLM_MAX_TOKENS: int = 512
    LLM_TIMEOUT: int = 30
    
    # Alternative: Groq API (free tier)
    GROQ_API_KEY: Optional[str] = None
    GROQ_MODEL: str = "mixtral-8x7b-32768"
    USE_GROQ: bool = False
    
    # Vector Database
    EMBEDDING_MODEL: str = "sentence-transformers/all-MiniLM-L6-v2"
    FAISS_INDEX_PATH: str = "./app/data/faiss_index/knowledge_base.index"
    TOP_K_RESULTS: int = 5
    SIMILARITY_THRESHOLD: float = 0.3
    
    # Authentication
    SECRET_KEY: str = "change-this-in-production-use-strong-secret"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 20
    RATE_LIMIT_PER_HOUR: int = 500
    
    # Logging
    LOG_LEVEL: str = "INFO"
    LOG_FILE: str = "./logs/app.log"
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # Data paths
    DATA_DIR: str = "./app/data"
    KNOWLEDGE_BASE_DIR: str = "./app/data/knowledge_base"
    CROPS_DB_PATH: str = "./app/data/crops.json"
    SCHEMES_DB_PATH: str = "./app/data/schemes.json"
    
    # Features
    ENABLE_WEATHER: bool = True
    ENABLE_MARKET_PRICES: bool = True
    ENABLE_SCHEMES: bool = True
    ENABLE_IMAGE_ANALYSIS: bool = False  # For future plant disease detection
    
    # Monitoring
    ENABLE_METRICS: bool = True
    METRICS_PORT: int = 9090
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# Create global settings instance
settings = Settings()


# Utility functions
def get_data_path(filename: str) -> str:
    """Get full path for data file"""
    return os.path.join(settings.DATA_DIR, filename)


def get_knowledge_base_path(filename: str) -> str:
    """Get full path for knowledge base file"""
    return os.path.join(settings.KNOWLEDGE_BASE_DIR, filename)


# Validate settings on import
def validate_settings():
    """Validate critical settings"""
    errors = []
    
    # Check required paths exist or can be created
    for path in [settings.DATA_DIR, settings.KNOWLEDGE_BASE_DIR]:
        os.makedirs(path, exist_ok=True)
    
    # Warn about debug mode in production
    if settings.ENVIRONMENT == "production" and settings.DEBUG:
        errors.append("DEBUG should be False in production")
    
    # Validate LLM configuration
    if not settings.USE_GROQ and not settings.OLLAMA_HOST:
        errors.append("Either Ollama or Groq must be configured")
    
    if errors:
        print("⚠️ Configuration warnings:")
        for error in errors:
            print(f"  - {error}")


# Run validation
validate_settings()