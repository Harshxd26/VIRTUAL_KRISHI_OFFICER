"""
Health Check Routes
"""

from fastapi import APIRouter
from datetime import datetime

from app.config import settings
from app.models.response_models import HealthResponse
from app.services.retrieval.vector_store import vector_store
from app.services.retrieval.structured_db import db_manager
from app.core.cache import cache_manager
from app.services.llm.ollama_client import llm_client

router = APIRouter()


@router.get("/", response_model=HealthResponse)
async def health_check():
    """Basic health check"""
    return HealthResponse(
        status="healthy",
        version=settings.APP_VERSION,
        environment=settings.ENVIRONMENT,
        timestamp=datetime.now(),
        services={}
    )


@router.get("/detailed", response_model=HealthResponse)
async def detailed_health_check():
    """Detailed health check with service status"""
    
    services = {}
    
    # Check vector store
    try:
        stats = vector_store.get_stats()
        services["vector_store"] = stats["total_vectors"] > 0
    except:
        services["vector_store"] = False
    
    # Check database
    try:
        services["database"] = db_manager.connection is not None
    except:
        services["database"] = False
    
    # Check cache
    try:
        cache_stats = cache_manager.get_stats()
        services["cache"] = cache_stats.get("type") != "disabled"
    except:
        services["cache"] = False
    
    # Check LLM
    try:
        services["llm"] = await llm_client.check_health()
    except:
        services["llm"] = False
    
    # Overall status
    all_critical_up = services.get("vector_store", False) and services.get("llm", False)
    status = "healthy" if all_critical_up else "degraded"
    
    return HealthResponse(
        status=status,
        version=settings.APP_VERSION,
        environment=settings.ENVIRONMENT,
        timestamp=datetime.now(),
        services=services
    )


@router.get("/ready")
async def readiness_check():
    """Kubernetes readiness probe"""
    return {"ready": True}


@router.get("/live")
async def liveness_check():
    """Kubernetes liveness probe"""
    return {"alive": True}