"""
Populate Database Script
Loads crops and schemes data into SQLite database
"""

import asyncio
import sys
import json
from pathlib import Path

# Add app to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.services.retrieval.structured_db import db_manager
from app.config import settings
from app.utils.logger import setup_logging

logger = setup_logging()


async def create_sample_data():
    """Create sample data files if they don't exist"""
    
    # Ensure data directory exists
    data_dir = Path(settings.DATA_DIR)
    data_dir.mkdir(parents=True, exist_ok=True)
    
    crops_file = Path(settings.CROPS_DB_PATH)
    schemes_file = Path(settings.SCHEMES_DB_PATH)
    
    # Sample data already created in JSON artifacts
    # This function just ensures the files exist
    
    if not crops_file.exists():
        logger.warning(f"Crops data file not found at {crops_file}")
        logger.info("Please ensure app/data/crops.json exists")
        return False
    
    if not schemes_file.exists():
        logger.warning(f"Schemes data file not found at {schemes_file}")
        logger.info("Please ensure app/data/schemes.json exists")
        return False
    
    return True


async def main():
    """Main function to populate database"""
    
    logger.info("=" * 60)
    logger.info("Populating Database")
    logger.info("=" * 60)
    
    # Check data files
    if not await create_sample_data():
        logger.error("Data files not found. Please create them first.")
        return
    
    try:
        # Initialize database
        await db_manager.initialize()
        
        # Get counts
        async with db_manager.connection.cursor() as cursor:
            await cursor.execute("SELECT COUNT(*) FROM crops")
            crop_count = (await cursor.fetchone())[0]
            
            await cursor.execute("SELECT COUNT(*) FROM schemes")
            scheme_count = (await cursor.fetchone())[0]
        
        logger.info("=" * 60)
        logger.info("✅ Database Populated Successfully!")
        logger.info(f"Crops: {crop_count}")
        logger.info(f"Schemes: {scheme_count}")
        logger.info("=" * 60)
        
    except Exception as e:
        logger.error(f"❌ Failed to populate database: {e}")
        raise
    finally:
        await db_manager.close()


if __name__ == "__main__":
    asyncio.run(main())