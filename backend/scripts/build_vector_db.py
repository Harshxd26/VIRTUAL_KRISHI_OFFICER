"""
Build FAISS Vector Database from Knowledge Base
Run this script after populating the knowledge_base directory
"""

import asyncio
import sys
from pathlib import Path

# Add app to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.services.retrieval.vector_store import vector_store, build_index_from_directory
from app.config import settings
from app.utils.logger import setup_logging

logger = setup_logging()


async def main():
    """Build vector database from knowledge base"""
    
    logger.info("=" * 60)
    logger.info("Building FAISS Vector Database")
    logger.info("=" * 60)
    
    # Check if knowledge base directory exists
    kb_dir = Path(settings.KNOWLEDGE_BASE_DIR)
    if not kb_dir.exists():
        logger.error(f"Knowledge base directory not found: {kb_dir}")
        logger.info("Creating directory...")
        kb_dir.mkdir(parents=True, exist_ok=True)
        
        # Create sample files
        create_sample_knowledge_base(kb_dir)
    
    # Count files
    txt_files = list(kb_dir.glob("**/*.txt"))
    logger.info(f"Found {len(txt_files)} text files to process")
    
    if not txt_files:
        logger.warning("No text files found. Creating sample data...")
        create_sample_knowledge_base(kb_dir)
        txt_files = list(kb_dir.glob("**/*.txt"))
    
    # Build index
    try:
        await build_index_from_directory(str(kb_dir))
        
        # Verify
        stats = vector_store.get_stats()
        logger.info("=" * 60)
        logger.info("✅ Vector Database Built Successfully!")
        logger.info(f"Total documents: {stats['total_documents']}")
        logger.info(f"Total vectors: {stats['total_vectors']}")
        logger.info(f"Dimension: {stats['dimension']}")
        logger.info(f"Model: {stats['model']}")
        logger.info(f"Index saved to: {stats['index_path']}")
        logger.info("=" * 60)
        
    except Exception as e:
        logger.error(f"❌ Failed to build vector database: {e}")
        raise


def create_sample_knowledge_base(kb_dir: Path):
    """Create sample knowledge base files"""
    
    logger.info("Creating sample knowledge base files...")
    
    # Sample content for different agricultural topics
    samples = {
        "crop_cultivation.txt": """
Wheat Cultivation Guide

Wheat (Triticum aestivum) is one of the most important cereal crops grown worldwide. 
In India, wheat is primarily a Rabi crop, sown in October-November and harvested in March-April.

Climate Requirements:
Wheat grows best in cool, moist conditions during the growing season and warm, dry weather during ripening. 
The ideal temperature range is 10-25°C. The crop requires about 450-650mm of rainfall, well-distributed throughout the growing period.

Soil Requirements:
Wheat can be grown on a variety of soils, but well-drained loamy soils with good fertility are ideal. 
The soil pH should be between 6.5 and 7.5. Good drainage is essential as waterlogging can severely damage the crop.

Sowing Time:
- Early sowing: Mid-October to end of October (for timely sown wheat)
- Normal sowing: First fortnight of November
- Late sowing: After November 25 (reduce seed rate by 25%)

Seed Rate:
- Normal conditions: 100 kg/ha
- Late sowing: 125 kg/ha
- Irrigated conditions: 100-125 kg/ha

Irrigation:
Wheat requires 5-6 irrigations:
1. Crown root initiation (20-25 days after sowing)
2. Tillering stage (40-45 DAS)
3. Jointing stage (60-65 DAS)
4. Flowering stage (80-85 DAS)
5. Milk stage (100-105 DAS)
6. Dough stage (115-120 DAS)

Fertilizer Management:
Apply N:P:K in the ratio of 120:60:40 kg/ha for high-yielding varieties.
- Full dose of P and K at sowing
- Nitrogen in 2-3 split doses

Common Varieties:
HD-2967, PBW-343, WH-542, DBW-17, HD-3086
        """,
        
        "pest_management.txt": """
Integrated Pest Management in Agriculture

Aphids:
Aphids are small, soft-bodied insects that suck plant sap. They multiply rapidly and can transmit viral diseases.

Symptoms:
- Curled and yellowing leaves
- Sticky honeydew on leaves
- Presence of black sooty mold
- Stunted plant growth

Management:
1. Cultural: Grow aphid-resistant varieties, use reflective mulches
2. Biological: Encourage ladybugs, lacewings, and parasitic wasps
3. Chemical: Spray neem oil or use systemic insecticides like imidacloprid (only when threshold is crossed)

Threshold: 5-10 aphids per leaf

Rust Diseases:
Rust diseases are caused by fungal pathogens and appear as orange-brown pustules on leaves and stems.

Symptoms:
- Yellow, orange, or brown pustules on leaves
- Premature leaf drop
- Reduced grain filling

Management:
1. Use resistant varieties
2. Remove and destroy infected plant debris
3. Apply fungicides like propiconazole or tebuconazole at first sign of disease
4. Avoid excessive nitrogen fertilization

Best Practices:
- Regular crop monitoring
- Crop rotation
- Maintain field hygiene
- Use certified disease-free seeds
- Apply pesticides only when economic threshold is reached
        """,
        
        "soil_health.txt": """
Soil Health Management

Soil Testing:
Regular soil testing is essential for sustainable agriculture. Test soil every 2-3 years to monitor:
- pH level
- Organic carbon content
- Available nitrogen, phosphorus, and potassium
- Micronutrients (zinc, iron, manganese, copper)

Soil Health Card:
The government provides free soil testing and issues Soil Health Cards that recommend:
- Nutrient application rates
- Organic amendments
- Lime or gypsum application for pH correction

Improving Soil Health:

1. Organic Matter Addition:
- Apply 5-10 tonnes of farmyard manure per hectare annually
- Use compost, vermicompost, or green manure
- Incorporate crop residues

2. Crop Rotation:
- Rotate cereals with legumes
- Include deep-rooted crops
- Practice mixed cropping

3. Cover Cropping:
- Grow cover crops during fallow periods
- Use leguminous crops to fix nitrogen
- Prevent soil erosion

4. Balanced Fertilization:
- Apply fertilizers based on soil test results
- Use both macro and micronutrients
- Apply organic and inorganic fertilizers in balance

5. Minimal Tillage:
- Reduce excessive plowing
- Practice conservation agriculture
- Maintain soil structure

Signs of Poor Soil Health:
- Poor water infiltration
- Soil compaction
- Reduced crop yields
- Increased pest and disease problems
- Nutrient deficiency symptoms in crops
        """,
        
        "farming_techniques.txt": """
Modern Farming Techniques

Drip Irrigation:
Drip irrigation delivers water directly to plant roots, reducing water wastage.

Advantages:
- 30-70% water savings compared to flood irrigation
- Reduced weed growth
- Lower labor costs
- Precise fertilizer application (fertigation)
- Suitable for water-scarce regions

System Components:
- Main line, sub-main, lateral pipes
- Drippers or emitters
- Filters and pressure regulators
- Fertilizer tank (for fertigation)

Crop Suitability: Vegetables, fruits, cotton, sugarcane

Mulching:
Mulching involves covering soil surface with organic or synthetic materials.

Benefits:
- Conserves soil moisture
- Regulates soil temperature
- Suppresses weeds
- Improves soil structure
- Reduces soil erosion

Types:
1. Organic mulch: Straw, leaves, grass clippings, crop residues
2. Inorganic mulch: Plastic films, landscape fabric

Zero Tillage:
Sowing crops without plowing, using specialized zero-till seed drills.

Advantages:
- Saves time and fuel
- Reduces soil erosion
- Improves soil structure
- Increases soil organic matter
- Enables timely sowing

Suitable Crops: Wheat after rice, maize, pulses

Precision Agriculture:
Using technology for optimal crop management.

Technologies:
- GPS-guided tractors
- Soil sensors
- Drone-based crop monitoring
- Variable rate technology
- Weather-based advisories

Benefits:
- Optimized input use
- Increased yields
- Reduced environmental impact
- Data-driven decision making
        """
    }
    
    # Write files
    for filename, content in samples.items():
        file_path = kb_dir / filename
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        logger.info(f"Created: {filename}")
    
    logger.info(f"✅ Created {len(samples)} sample knowledge base files")


if __name__ == "__main__":
    asyncio.run(main())