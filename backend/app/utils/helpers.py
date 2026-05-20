"""
Helper utility functions
"""

import hashlib
import json
from typing import Any, Dict, List
from datetime import datetime


def generate_cache_key(*args) -> str:
    """Generate cache key from arguments"""
    key_string = "|".join(str(arg) for arg in args)
    return hashlib.md5(key_string.encode()).hexdigest()


def clean_text(text: str) -> str:
    """Clean and normalize text"""
    if not text:
        return ""
    
    # Remove extra whitespace
    text = " ".join(text.split())
    
    # Remove special characters but keep basic punctuation
    text = text.strip()
    
    return text


def truncate_text(text: str, max_length: int = 500) -> str:
    """Truncate text to max length"""
    if len(text) <= max_length:
        return text
    
    return text[:max_length-3] + "..."


def extract_keywords(text: str, top_n: int = 5) -> List[str]:
    """Extract top keywords from text (simple implementation)"""
    # Remove common words
    common_words = {
        'the', 'is', 'at', 'which', 'on', 'a', 'an', 'and', 'or', 
        'but', 'in', 'with', 'to', 'for', 'of', 'as', 'by'
    }
    
    words = text.lower().split()
    words = [w.strip('.,!?;:') for w in words if w.strip('.,!?;:')]
    words = [w for w in words if len(w) > 3 and w not in common_words]
    
    # Count frequency
    word_freq = {}
    for word in words:
        word_freq[word] = word_freq.get(word, 0) + 1
    
    # Get top N
    sorted_words = sorted(word_freq.items(), key=lambda x: x[1], reverse=True)
    return [word for word, _ in sorted_words[:top_n]]


def merge_dicts(dict1: Dict, dict2: Dict) -> Dict:
    """Merge two dictionaries recursively"""
    result = dict1.copy()
    
    for key, value in dict2.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = merge_dicts(result[key], value)
        else:
            result[key] = value
    
    return result


def safe_json_loads(json_string: str, default: Any = None) -> Any:
    """Safely load JSON string"""
    try:
        return json.loads(json_string)
    except (json.JSONDecodeError, TypeError):
        return default


def format_timestamp(dt: datetime = None) -> str:
    """Format datetime to ISO string"""
    if dt is None:
        dt = datetime.now()
    return dt.isoformat()


def calculate_similarity_score(text1: str, text2: str) -> float:
    """Calculate simple text similarity (Jaccard similarity)"""
    if not text1 or not text2:
        return 0.0
    
    words1 = set(text1.lower().split())
    words2 = set(text2.lower().split())
    
    intersection = len(words1.intersection(words2))
    union = len(words1.union(words2))
    
    return intersection / union if union > 0 else 0.0