"""
Dependency Injection
FastAPI dependencies for shared resources
"""

from typing import Optional
from fastapi import Depends, Request

from app.services.retrieval.vector_store import vector_store
from app.services.retrieval.structured_db import db_manager
from app.core.cache import cache_manager
from app.services.llm.ollama_client import llm_client


async def get_vector_store():
    """Get vector store dependency"""
    return vector_store


async def get_database():
    """Get database dependency"""
    return db_manager


async def get_cache():
    """Get cache dependency"""
    return cache_manager


async def get_llm_client():
    """Get LLM client dependency"""
    return llm_client


async def get_client_ip(request: Request) -> str:
    """Get client IP address"""
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0]
    return request.client.host