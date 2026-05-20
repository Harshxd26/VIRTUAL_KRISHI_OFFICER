"""
Rate Limiting Middleware
"""

from fastapi import HTTPException, Request
from collections import defaultdict
from datetime import datetime, timedelta
from typing import Dict

from app.config import settings


class RateLimiter:
    """Simple in-memory rate limiter"""
    
    def __init__(self):
        self.requests: Dict[str, list] = defaultdict(list)
        self.per_minute = settings.RATE_LIMIT_PER_MINUTE
        self.per_hour = settings.RATE_LIMIT_PER_HOUR
    
    def check_rate_limit(self, client_id: str):
        """Check if client has exceeded rate limit"""
        now = datetime.now()
        
        # Clean old requests
        self.requests[client_id] = [
            req_time for req_time in self.requests[client_id]
            if now - req_time < timedelta(hours=1)
        ]
        
        # Check per minute limit
        minute_ago = now - timedelta(minutes=1)
        recent_requests = [
            req_time for req_time in self.requests[client_id]
            if req_time > minute_ago
        ]
        
        if len(recent_requests) >= self.per_minute:
            raise HTTPException(
                status_code=429,
                detail=f"Rate limit exceeded: {self.per_minute} requests per minute"
            )
        
        # Check per hour limit
        if len(self.requests[client_id]) >= self.per_hour:
            raise HTTPException(
                status_code=429,
                detail=f"Rate limit exceeded: {self.per_hour} requests per hour"
            )
        
        # Record request
        self.requests[client_id].append(now)


# Global rate limiter
rate_limiter = RateLimiter()


async def rate_limit_dependency(request: Request):
    """FastAPI dependency for rate limiting"""
    # Use IP address as client identifier
    client_ip = request.client.host
    rate_limiter.check_rate_limit(client_ip)