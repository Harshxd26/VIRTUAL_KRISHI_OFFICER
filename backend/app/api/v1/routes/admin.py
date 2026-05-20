"""
Admin Routes - System management endpoints
"""

from fastapi import APIRouter, HTTPException
from typing import Dict

from app.services.retrieval.vector_store import vector_store
from app.services.retrieval.structured_db import db_manager
from app.core.cache import cache_manager
from app.utils.metrics import get_metrics

router = APIRouter()


@router.get("/stats")
async def get_system_stats() -> Dict:
    """Get system statistics"""
    
    stats = {
        "vector_store": vector_store.get_stats(),
        "cache": cache_manager.get_stats(),
        "metrics": get_metrics(),
    }
    
    # Get database stats
    try:
        # Count crops and schemes
        if db_manager.connection:
            async with db_manager.connection.cursor() as cursor:
                await cursor.execute("SELECT COUNT(*) FROM crops")
                crop_count = (await cursor.fetchone())[0]
                
                await cursor.execute("SELECT COUNT(*) FROM schemes")
                scheme_count = (await cursor.fetchone())[0]
                
                stats["database"] = {
                    "crops": crop_count,
                    "schemes": scheme_count
                }
    except Exception as e:
        stats["database"] = {"error": str(e)}
    
    return stats


@router.post("/cache/clear")
async def clear_cache():
    """Clear application cache"""
    try:
        await cache_manager.clear()
        return {"message": "Cache cleared successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/config")
async def get_config() -> Dict:
    """Get current configuration (non-sensitive)"""
    from app.config import settings
    
    return {
        "app_name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
        "debug": settings.DEBUG,
        "features": {
            "weather": settings.ENABLE_WEATHER,
            "market_prices": settings.ENABLE_MARKET_PRICES,
            "schemes": settings.ENABLE_SCHEMES,
            "cache": settings.ENABLE_CACHE,
        },
        "llm": {
            "model": settings.OLLAMA_MODEL if not settings.USE_GROQ else settings.GROQ_MODEL,
            "use_groq": settings.USE_GROQ,
        }
    }


@router.post("/rebuild-index")
async def rebuild_index():
    """Rebuild FAISS vector index from knowledge base files"""
    try:
        from app.services.retrieval.vector_store import build_index_from_directory
        from app.config import settings
        from pathlib import Path
        
        kb_dir = Path(settings.KNOWLEDGE_BASE_DIR)
        if not kb_dir.exists():
            raise HTTPException(
                status_code=404,
                detail=f"Knowledge base directory not found: {kb_dir}"
            )
        
        # Rebuild index
        await build_index_from_directory(str(kb_dir))
        
        # Get stats
        stats = vector_store.get_stats()
        
        return {
            "message": "Index rebuilt successfully",
            "stats": stats
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))