"""
Structured Database - SQLite for crops, schemes, and structured data
"""

import json
import sqlite3
from pathlib import Path
from typing import Optional, List, Dict, Any
import aiosqlite

from app.config import settings
from app.utils.logger import setup_logging

logger = setup_logging()


class DatabaseManager:
    """Manage structured agricultural data"""
    
    def __init__(self):
        self.db_path = settings.DATABASE_URL.replace("sqlite:///", "")
        self.connection: Optional[aiosqlite.Connection] = None
    
    async def initialize(self):
        """Initialize database and create tables"""
        try:
            # Create data directory if needed
            Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
            
            # Connect to database
            self.connection = await aiosqlite.connect(self.db_path)
            self.connection.row_factory = aiosqlite.Row
            
            # Create tables
            await self._create_tables()
            
            # Load initial data if tables are empty
            await self._load_initial_data()
            
            logger.info("✅ Database initialized")
            
        except Exception as e:
            logger.error(f"Database initialization failed: {e}")
            raise
    
    async def _create_tables(self):
        """Create database tables"""
        async with self.connection.cursor() as cursor:
            # Crops table
            await cursor.execute("""
                CREATE TABLE IF NOT EXISTS crops (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    scientific_name TEXT,
                    category TEXT,
                    seasons TEXT,
                    soil_types TEXT,
                    water_requirement TEXT,
                    growth_duration_days INTEGER,
                    optimal_temp_min REAL,
                    optimal_temp_max REAL,
                    common_pests TEXT,
                    common_diseases TEXT,
                    fertilizer_npk TEXT,
                    irrigation_schedule TEXT,
                    varieties TEXT,
                    additional_info TEXT
                )
            """)
            
            # Government schemes table
            await cursor.execute("""
                CREATE TABLE IF NOT EXISTS schemes (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    description TEXT,
                    category TEXT,
                    eligibility TEXT,
                    benefit TEXT,
                    application_url TEXT,
                    contact_info TEXT,
                    documents_required TEXT,
                    state TEXT,
                    active INTEGER DEFAULT 1
                )
            """)
            
            # Market prices table (for caching)
            await cursor.execute("""
                CREATE TABLE IF NOT EXISTS market_prices (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    commodity TEXT NOT NULL,
                    price REAL NOT NULL,
                    unit TEXT DEFAULT 'quintal',
                    market TEXT,
                    state TEXT,
                    date TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            await self.connection.commit()
    
    async def _load_initial_data(self):
        """Load initial data from JSON files"""
        # Check if data already exists
        async with self.connection.cursor() as cursor:
            await cursor.execute("SELECT COUNT(*) FROM crops")
            crop_count = (await cursor.fetchone())[0]
            
            if crop_count > 0:
                logger.info("Database already has data, skipping initial load")
                return
        
        # Load crops data
        crops_file = Path(settings.CROPS_DB_PATH)
        if crops_file.exists():
            with open(crops_file, 'r') as f:
                crops_data = json.load(f)
                await self._insert_crops(crops_data.get("crops", []))
        
        # Load schemes data
        schemes_file = Path(settings.SCHEMES_DB_PATH)
        if schemes_file.exists():
            with open(schemes_file, 'r') as f:
                schemes_data = json.load(f)
                await self._insert_schemes(schemes_data.get("schemes", []))
        
        logger.info("✅ Initial data loaded")
    
    async def _insert_crops(self, crops: List[Dict]):
        """Insert crop data"""
        async with self.connection.cursor() as cursor:
            for crop in crops:
                await cursor.execute("""
                    INSERT OR REPLACE INTO crops (
                        id, name, scientific_name, category, seasons,
                        soil_types, water_requirement, growth_duration_days,
                        optimal_temp_min, optimal_temp_max, common_pests,
                        common_diseases, fertilizer_npk, irrigation_schedule,
                        varieties, additional_info
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    crop.get("id"),
                    crop.get("name"),
                    crop.get("scientific_name"),
                    crop.get("category"),
                    json.dumps(crop.get("seasons", [])),
                    json.dumps(crop.get("soil_types", [])),
                    crop.get("water_requirement"),
                    crop.get("growth_duration_days"),
                    crop.get("optimal_temp_range", [0, 0])[0],
                    crop.get("optimal_temp_range", [0, 0])[1] if len(crop.get("optimal_temp_range", [])) > 1 else 0,
                    json.dumps(crop.get("common_pests", [])),
                    json.dumps(crop.get("common_diseases", [])),
                    json.dumps(crop.get("fertilizer_npk", {})),
                    json.dumps(crop.get("irrigation_schedule", {})),
                    json.dumps(crop.get("varieties", [])),
                    json.dumps(crop.get("additional_info", {}))
                ))
            
            await self.connection.commit()
            logger.info(f"Inserted {len(crops)} crops")
    
    async def _insert_schemes(self, schemes: List[Dict]):
        """Insert scheme data"""
        async with self.connection.cursor() as cursor:
            for scheme in schemes:
                await cursor.execute("""
                    INSERT OR REPLACE INTO schemes (
                        id, name, description, category, eligibility,
                        benefit, application_url, contact_info,
                        documents_required, state, active
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    scheme.get("id"),
                    scheme.get("name"),
                    scheme.get("description"),
                    scheme.get("category", "general"),
                    scheme.get("eligibility"),
                    scheme.get("benefit"),
                    scheme.get("application_url"),
                    scheme.get("contact_info"),
                    json.dumps(scheme.get("documents_required", [])),
                    scheme.get("state", "all"),
                    1
                ))
            
            await self.connection.commit()
            logger.info(f"Inserted {len(schemes)} schemes")
    
    async def get_crop_info(self, crop_name: Optional[str]) -> Optional[Dict]:
        """Get crop information"""
        if not crop_name:
            return None
        
        try:
            async with self.connection.cursor() as cursor:
                await cursor.execute(
                    "SELECT * FROM crops WHERE LOWER(name) = LOWER(?)",
                    (crop_name,)
                )
                row = await cursor.fetchone()
                
                if row:
                    return dict(row)
                
                return None
                
        except Exception as e:
            logger.error(f"Error getting crop info: {e}")
            return None
    
    async def search_crops(self, query: str, limit: int = 5) -> List[Dict]:
        """Search crops by name or category"""
        try:
            async with self.connection.cursor() as cursor:
                await cursor.execute("""
                    SELECT * FROM crops 
                    WHERE LOWER(name) LIKE LOWER(?) 
                    OR LOWER(category) LIKE LOWER(?)
                    LIMIT ?
                """, (f"%{query}%", f"%{query}%", limit))
                
                rows = await cursor.fetchall()
                return [dict(row) for row in rows]
                
        except Exception as e:
            logger.error(f"Error searching crops: {e}")
            return []
    
    async def get_scheme_info(self, scheme_id: str) -> Optional[Dict]:
        """Get scheme information"""
        try:
            async with self.connection.cursor() as cursor:
                await cursor.execute(
                    "SELECT * FROM schemes WHERE id = ? AND active = 1",
                    (scheme_id,)
                )
                row = await cursor.fetchone()
                
                if row:
                    return dict(row)
                
                return None
                
        except Exception as e:
            logger.error(f"Error getting scheme info: {e}")
            return None
    
    async def search_schemes(self, query: str, state: Optional[str] = None) -> List[Dict]:
        """Search government schemes"""
        try:
            async with self.connection.cursor() as cursor:
                if state:
                    await cursor.execute("""
                        SELECT * FROM schemes 
                        WHERE active = 1 
                        AND (LOWER(name) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?))
                        AND (state = ? OR state = 'all')
                        LIMIT 5
                    """, (f"%{query}%", f"%{query}%", state.lower()))
                else:
                    await cursor.execute("""
                        SELECT * FROM schemes 
                        WHERE active = 1 
                        AND (LOWER(name) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?))
                        LIMIT 5
                    """, (f"%{query}%", f"%{query}%"))
                
                rows = await cursor.fetchall()
                return [dict(row) for row in rows]
                
        except Exception as e:
            logger.error(f"Error searching schemes: {e}")
            return []
    
    async def close(self):
        """Close database connection"""
        if self.connection:
            await self.connection.close()
            logger.info("Database connection closed")


# Global database manager
db_manager = DatabaseManager()