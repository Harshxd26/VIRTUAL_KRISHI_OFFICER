"""
Government Schemes Service
"""

from typing import List, Dict, Optional
from app.services.retrieval.structured_db import db_manager
from app.utils.logger import setup_logging

logger = setup_logging()


class SchemeService:
    """Manage government schemes information"""
    
    async def search_schemes(
        self,
        query: str,
        state: Optional[str] = None
    ) -> List[Dict]:
        """
        Search for relevant government schemes
        
        Args:
            query: Search query
            state: State for location-specific schemes
            
        Returns:
            List of matching schemes
        """
        try:
            schemes = await db_manager.search_schemes(query, state)
            logger.info(f"Found {len(schemes)} schemes for query: {query}")
            return schemes
            
        except Exception as e:
            logger.error(f"Error searching schemes: {e}")
            return []
    
    async def get_scheme_details(self, scheme_id: str) -> Optional[Dict]:
        """Get detailed information about a scheme"""
        try:
            scheme = await db_manager.get_scheme_info(scheme_id)
            return scheme
            
        except Exception as e:
            logger.error(f"Error getting scheme details: {e}")
            return None
    
    async def get_popular_schemes(self, limit: int = 5) -> List[Dict]:
        """Get list of popular/important schemes"""
        # This would be based on usage/importance
        popular = [
            "pmkisan",
            "kisan_credit_card",
            "crop_insurance",
            "soil_health_card",
            "fasal_bima"
        ]
        
        schemes = []
        for scheme_id in popular[:limit]:
            scheme = await self.get_scheme_details(scheme_id)
            if scheme:
                schemes.append(scheme)
        
        return schemes


# Global instance
scheme_service = SchemeService()