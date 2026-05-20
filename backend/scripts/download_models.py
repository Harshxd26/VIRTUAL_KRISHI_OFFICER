"""
Download Models Script
Downloads required embedding models
"""

import sys
from pathlib import Path

# Add app to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from sentence_transformers import SentenceTransformer
from app.config import settings
from app.utils.logger import setup_logging

logger = setup_logging()


def main():
    """Download embedding model"""
    
    logger.info("=" * 60)
    logger.info("Downloading Embedding Model")
    logger.info("=" * 60)
    
    model_name = settings.EMBEDDING_MODEL
    logger.info(f"Model: {model_name}")
    
    try:
        # Download and cache model
        logger.info("Downloading... This may take a few minutes.")
        model = SentenceTransformer(model_name)
        
        # Test model
        test_text = "This is a test sentence for agricultural advisory."
        embedding = model.encode([test_text])
        
        logger.info("=" * 60)
        logger.info("✅ Model Downloaded Successfully!")
        logger.info(f"Embedding dimension: {len(embedding[0])}")
        logger.info("=" * 60)
        
    except Exception as e:
        logger.error(f"❌ Failed to download model: {e}")
        raise


if __name__ == "__main__":
    main()