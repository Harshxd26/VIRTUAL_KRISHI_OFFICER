"""
Embeddings Service - Wrapper for sentence transformers
"""

from sentence_transformers import SentenceTransformer
from typing import List, Optional
import numpy as np

from app.config import settings
from app.utils.logger import setup_logging

logger = setup_logging()


class EmbeddingService:
    """Generate embeddings for text"""
    
    def __init__(self):
        self.model_name = settings.EMBEDDING_MODEL
        self.model: Optional[SentenceTransformer] = None
        self.dimension: Optional[int] = None
    
    def load_model(self):
        """Load the embedding model"""
        if self.model is None:
            logger.info(f"Loading embedding model: {self.model_name}")
            self.model = SentenceTransformer(self.model_name)
            self.dimension = self.model.get_sentence_embedding_dimension()
            logger.info(f"✅ Model loaded (dimension: {self.dimension})")
    
    def encode(
        self,
        texts: List[str],
        batch_size: int = 32,
        normalize: bool = True
    ) -> np.ndarray:
        """
        Generate embeddings for texts
        
        Args:
            texts: List of text strings
            batch_size: Batch size for encoding
            normalize: Whether to normalize embeddings
            
        Returns:
            numpy array of embeddings
        """
        if self.model is None:
            self.load_model()
        
        embeddings = self.model.encode(
            texts,
            batch_size=batch_size,
            show_progress_bar=len(texts) > 100,
            normalize_embeddings=normalize
        )
        
        return embeddings
    
    def encode_single(self, text: str, normalize: bool = True) -> np.ndarray:
        """Encode single text"""
        return self.encode([text], normalize=normalize)[0]
    
    def get_dimension(self) -> int:
        """Get embedding dimension"""
        if self.dimension is None:
            self.load_model()
        return self.dimension


# Global embedding service
embedding_service = EmbeddingService()