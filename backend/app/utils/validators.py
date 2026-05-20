"""
Input validation utilities
"""

import re
from typing import Optional, Tuple


def validate_coordinates(latitude: float, longitude: float) -> Tuple[bool, Optional[str]]:
    """
    Validate geographic coordinates
    
    Returns:
        (is_valid, error_message)
    """
    if not (-90 <= latitude <= 90):
        return False, "Latitude must be between -90 and 90"
    
    if not (-180 <= longitude <= 180):
        return False, "Longitude must be between -180 and 180"
    
    return True, None


def validate_query(query: str) -> Tuple[bool, Optional[str]]:
    """
    Validate user query
    
    Returns:
        (is_valid, error_message)
    """
    if not query or not query.strip():
        return False, "Query cannot be empty"
    
    if len(query) < 3:
        return False, "Query must be at least 3 characters long"
    
    if len(query) > 1000:
        return False, "Query must be less than 1000 characters"
    
    # Check for suspicious patterns (basic SQL injection prevention)
    suspicious_patterns = [
        r'union\s+select',
        r'drop\s+table',
        r'delete\s+from',
        r'<script',
        r'javascript:',
    ]
    
    query_lower = query.lower()
    for pattern in suspicious_patterns:
        if re.search(pattern, query_lower):
            return False, "Query contains invalid patterns"
    
    return True, None


def sanitize_filename(filename: str) -> str:
    """Sanitize filename to prevent path traversal"""
    # Remove path separators and dangerous characters
    filename = re.sub(r'[/\\:*?"<>|]', '', filename)
    
    # Remove leading/trailing dots and spaces
    filename = filename.strip('. ')
    
    # Limit length
    if len(filename) > 255:
        filename = filename[:255]
    
    return filename or "unnamed"


def validate_language_code(lang: str) -> bool:
    """Validate language code (ISO 639-1)"""
    valid_codes = {
        'en', 'hi', 'bn', 'te', 'mr', 'ta', 'gu', 'kn', 'ml', 'pa', 'ur'
    }
    return lang.lower() in valid_codes


def validate_state_name(state: str) -> bool:
    """Validate Indian state name"""
    indian_states = {
        'andhra pradesh', 'arunachal pradesh', 'assam', 'bihar', 'chhattisgarh',
        'goa', 'gujarat', 'haryana', 'himachal pradesh', 'jharkhand', 'karnataka',
        'kerala', 'madhya pradesh', 'maharashtra', 'manipur', 'meghalaya', 'mizoram',
        'nagaland', 'odisha', 'punjab', 'rajasthan', 'sikkim', 'tamil nadu',
        'telangana', 'tripura', 'uttar pradesh', 'uttarakhand', 'west bengal',
        'andaman and nicobar', 'chandigarh', 'dadra and nagar haveli',
        'daman and diu', 'delhi', 'jammu and kashmir', 'ladakh', 'lakshadweep',
        'puducherry'
    }
    
    return state.lower() in indian_states


def validate_phone_number(phone: str) -> bool:
    """Validate Indian phone number"""
    # Remove spaces and special characters
    phone = re.sub(r'[\s\-\(\)]', '', phone)
    
    # Check pattern: +91 or 0 followed by 10 digits
    pattern = r'^(\+91|0)?[6-9]\d{9}$'
    return bool(re.match(pattern, phone))


def validate_email(email: str) -> bool:
    """Validate email address"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))