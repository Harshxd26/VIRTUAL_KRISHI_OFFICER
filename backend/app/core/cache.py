"""
Caching Layer - Supports both Redis and in-memory cache
"""

import json
from typing import Optional, Any
from datetime import datetime, timedelta
import asyncio

try:
    import redis.asyncio as aioredis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False

from app.config import settings
from app.utils.logger import setup_logging

logger = setup_logging()


class InMemoryCache:
    """Simple in-memory cache with TTL"""
    
    def __init__(self):
        self._cache = {}
        self._expiry = {}
    
    async def get(self, key: str) -> Optional[Any]:
        """Get value from cache"""
        # Check if expired
        if key in self._expiry:
            if datetime.now() > self._expiry[key]:
                await self.delete(key)
                return None
        
        return self._cache.get(key)
    
    async def set(self, key: str, value: Any, ttl: int = 3600):
        """Set value in cache with TTL"""
        self._cache[key] = value
        self._expiry[key] = datetime.now() + timedelta(seconds=ttl)
    
    async def delete(self, key: str):
        """Delete key from cache"""
        self._cache.pop(key, None)
        self._expiry.pop(key, None)
    
    async def clear(self):
        """Clear all cache"""
        self._cache.clear()
        self._expiry.clear()
    
    def get_stats(self):
        """Get cache statistics"""
        return {
            "type": "in_memory",
            "keys": len(self._cache),
            "memory_mb": sum(
                len(str(v).encode()) for v in self._cache.values()
            ) / (1024 * 1024)
        }


class RedisCache:
    """Redis-based cache"""
    
    def __init__(self, redis_url: str):
        self.redis_url = redis_url
        self.client: Optional[aioredis.Redis] = None
    
    async def connect(self):
        """Connect to Redis"""
        try:
            self.client = await aioredis.from_url(
                self.redis_url,
                encoding="utf-8",
                decode_responses=True
            )
            await self.client.ping()
            logger.info("✅ Connected to Redis")
        except Exception as e:
            logger.error(f"Failed to connect to Redis: {e}")
            raise
    
    async def get(self, key: str) -> Optional[Any]:
        """Get value from Redis"""
        if not self.client:
            return None
        
        try:
            value = await self.client.get(key)
            if value:
                return json.loads(value)
            return None
        except Exception as e:
            logger.error(f"Redis GET error: {e}")
            return None
    
    async def set(self, key: str, value: Any, ttl: int = 3600):
        """Set value in Redis with TTL"""
        if not self.client:
            return
        
        try:
            serialized = json.dumps(value)
            await self.client.setex(key, ttl, serialized)
        except Exception as e:
            logger.error(f"Redis SET error: {e}")
    
    async def delete(self, key: str):
        """Delete key from Redis"""
        if not self.client:
            return
        
        try:
            await self.client.delete(key)
        except Exception as e:
            logger.error(f"Redis DELETE error: {e}")
    
    async def clear(self):
        """Clear all cache"""
        if not self.client:
            return
        
        try:
            await self.client.flushdb()
        except Exception as e:
            logger.error(f"Redis CLEAR error: {e}")
    
    async def close(self):
        """Close Redis connection"""
        if self.client:
            await self.client.close()
    
    def get_stats(self):
        """Get cache statistics"""
        return {
            "type": "redis",
            "connected": self.client is not None
        }


class CacheManager:
    """Unified cache manager"""
    
    def __init__(self):
        self.cache = None
        self.enabled = settings.ENABLE_CACHE
    
    async def initialize(self):
        """Initialize cache backend"""
        if not self.enabled:
            logger.info("Cache disabled")
            return
        
        # Try Redis first
        if settings.REDIS_URL and REDIS_AVAILABLE:
            try:
                self.cache = RedisCache(settings.REDIS_URL)
                await self.cache.connect()
                logger.info("✅ Using Redis cache")
                return
            except Exception as e:
                logger.warning(f"Redis unavailable: {e}. Falling back to in-memory cache")
        
        # Fallback to in-memory
        self.cache = InMemoryCache()
        logger.info("✅ Using in-memory cache")
    
    async def get(self, key: str) -> Optional[Any]:
        """Get value from cache"""
        if not self.enabled or not self.cache:
            return None
        
        return await self.cache.get(key)
    
    async def set(self, key: str, value: Any, ttl: int = None):
        """Set value in cache"""
        if not self.enabled or not self.cache:
            return
        
        ttl = ttl or settings.CACHE_TTL
        await self.cache.set(key, value, ttl)
    
    async def delete(self, key: str):
        """Delete key from cache"""
        if not self.enabled or not self.cache:
            return
        
        await self.cache.delete(key)
    
    async def clear(self):
        """Clear all cache"""
        if not self.enabled or not self.cache:
            return
        
        await self.cache.clear()
    
    async def close(self):
        """Close cache connection"""
        if self.cache and hasattr(self.cache, 'close'):
            await self.cache.close()
    
    def get_stats(self):
        """Get cache statistics"""
        if not self.cache:
            return {"type": "disabled"}
        
        return self.cache.get_stats()


# Global cache manager instance
cache_manager = CacheManager()