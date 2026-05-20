"""
Agricultural Advisory API - Main Application
FastAPI backend for agricultural advisory mobile app
"""

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import logging
from datetime import datetime

from app.config import settings
from app.api.v1.routes import query, health, admin
from app.core.cache import cache_manager
from app.services.retrieval.vector_store import vector_store
from app.services.retrieval.structured_db import db_manager
from app.utils.logger import setup_logging

# Setup logging
logger = setup_logging()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    logger.info("🚀 Starting Agricultural Advisory API...")
    
    # Initialize vector store
    try:
        await vector_store.initialize()
        logger.info("✅ Vector store initialized")
    except Exception as e:
        logger.error(f"❌ Vector store initialization failed: {e}")
    
    # Initialize database
    try:
        await db_manager.initialize()
        logger.info("✅ Database initialized")
    except Exception as e:
        logger.error(f"❌ Database initialization failed: {e}")
    
    # Initialize cache
    try:
        await cache_manager.initialize()
        logger.info("✅ Cache initialized")
    except Exception as e:
        logger.warning(f"⚠️ Cache initialization failed (continuing without cache): {e}")
    
    logger.info(f"✅ API ready at http://{settings.HOST}:{settings.PORT}")
    
    yield
    
    # Shutdown
    logger.info("🛑 Shutting down Agricultural Advisory API...")
    await cache_manager.close()
    await db_manager.close()
    logger.info("✅ Cleanup completed")


# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="AI-powered agricultural advisory system with RAG and real-time data",
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    lifespan=lifespan
)

# Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure based on your Flutter app domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(GZipMiddleware, minimum_size=1000)


# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = datetime.now()
    
    # Log request
    logger.info(f"[REQ] {request.method} {request.url.path}")
    
    response = await call_next(request)
    
    # Log response
    duration = (datetime.now() - start_time).total_seconds()
    logger.info(f"[RES]{request.method} {request.url.path} - {response.status_code} ({duration:.2f}s)")
    
    return response


# Exception handlers
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"❌ Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "success": False,
            "error": "Internal server error",
            "message": str(exc) if settings.DEBUG else "An unexpected error occurred"
        }
    )


# Include routers
app.include_router(health.router, prefix="/health", tags=["Health"])
app.include_router(query.router, prefix="/api/v1", tags=["Query"])
app.include_router(admin.router, prefix="/api/v1/admin", tags=["Admin"])


# Root endpoint
@app.get("/", tags=["Root"])
async def root():
    """Root endpoint with API information"""
    return {
        "name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "operational",
        "environment": settings.ENVIRONMENT,
        "endpoints": {
            "health": "/health",
            "query": "/api/v1/query",
            "docs": "/docs" if settings.DEBUG else "disabled"
        },
        "timestamp": datetime.now().isoformat()
    }


# Metrics endpoint for monitoring
@app.get("/metrics", tags=["Monitoring"])
async def metrics():
    """Prometheus-compatible metrics endpoint"""
    from app.utils.metrics import get_metrics
    return get_metrics()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )