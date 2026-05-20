"""
Metrics collection for monitoring
"""

from collections import defaultdict
from datetime import datetime
from typing import Dict


class MetricsCollector:
    """Simple metrics collector"""
    
    def __init__(self):
        self.request_count = 0
        self.error_count = 0
        self.total_processing_time = 0.0
        self.intent_counts = defaultdict(int)
        self.cache_hits = 0
        self.cache_misses = 0
        self.start_time = datetime.now()
    
    def record_request(self):
        """Record a request"""
        self.request_count += 1
    
    def record_error(self):
        """Record an error"""
        self.error_count += 1
    
    def record_processing_time(self, duration: float):
        """Record processing time"""
        self.total_processing_time += duration
    
    def record_intent(self, intent: str):
        """Record query intent"""
        self.intent_counts[intent] += 1
    
    def record_cache_hit(self):
        """Record cache hit"""
        self.cache_hits += 1
    
    def record_cache_miss(self):
        """Record cache miss"""
        self.cache_misses += 1
    
    def get_metrics(self) -> Dict:
        """Get current metrics"""
        uptime = (datetime.now() - self.start_time).total_seconds()
        
        avg_processing_time = (
            self.total_processing_time / self.request_count 
            if self.request_count > 0 
            else 0
        )
        
        cache_hit_rate = (
            self.cache_hits / (self.cache_hits + self.cache_misses)
            if (self.cache_hits + self.cache_misses) > 0
            else 0
        )
        
        return {
            "uptime_seconds": uptime,
            "total_requests": self.request_count,
            "total_errors": self.error_count,
            "error_rate": self.error_count / max(self.request_count, 1),
            "avg_processing_time_seconds": avg_processing_time,
            "cache_hit_rate": cache_hit_rate,
            "cache_hits": self.cache_hits,
            "cache_misses": self.cache_misses,
            "intent_distribution": dict(self.intent_counts),
            "start_time": self.start_time.isoformat()
        }
    
    def reset(self):
        """Reset metrics"""
        self.__init__()


# Global metrics collector
metrics_collector = MetricsCollector()


def get_metrics() -> Dict:
    """Get current metrics (for endpoint)"""
    return metrics_collector.get_metrics()