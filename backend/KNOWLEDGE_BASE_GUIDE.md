# Knowledge Base and FAISS Index Guide

## Overview
This guide explains how to populate the knowledge base files and build the FAISS vector index for semantic search in the agricultural advisory system.

## Knowledge Base Files

The knowledge base consists of text files in `backend/app/data/knowledge_base/`:

1. **crop_cultivation.txt** - Comprehensive crop cultivation guides
2. **pest_management.txt** - Pest and disease management information
3. **soil_health.txt** - Soil testing, health, and nutrient management
4. **farming_techniques.txt** - Modern farming techniques and practices

### Content Guidelines

Each knowledge base file should contain:
- **Structured information** organized by topics
- **Practical advice** relevant to Indian agriculture
- **Specific details** like quantities, timings, methods
- **Clear sections** separated by headings or paragraphs
- **Actionable recommendations** farmers can follow

### Example Structure:
```
TOPIC NAME
Brief introduction about the topic.

Key Points:
- Point 1 with details
- Point 2 with details

Methods:
1. Method name: Description
2. Method name: Description

Best Practices:
- Practice 1
- Practice 2
```

## Building the FAISS Index

### Prerequisites
- Python 3.8+
- Required packages: `faiss-cpu`, `sentence-transformers`, `numpy`
- Knowledge base files populated with content

### Method 1: Using the Build Script (Recommended)

```bash
cd backend
python scripts/build_vector_db.py
```

This script will:
1. Check if knowledge base files exist
2. Create sample files if directory is empty
3. Process all `.txt` files in the knowledge base directory
4. Split content into chunks (500 characters each)
5. Generate embeddings using `sentence-transformers/all-MiniLM-L6-v2`
6. Build and save the FAISS index to `backend/app/data/faiss_index/`

### Method 2: Manual Building via API

The index is automatically created on first startup if it doesn't exist, but it will be empty. To populate it:

1. Ensure knowledge base files are populated
2. Use the admin endpoint to rebuild:
   ```bash
   # After starting the server
   curl -X POST http://localhost:8000/api/v1/admin/rebuild-index
   ```

### Method 3: Programmatic Building

```python
import asyncio
from app.services.retrieval.vector_store import build_index_from_directory
from app.config import settings

async def build():
    await build_index_from_directory(settings.KNOWLEDGE_BASE_DIR)
    print("Index built successfully!")

asyncio.run(build())
```

## Index Location

- **Index file**: `backend/app/data/faiss_index/knowledge_base.index`
- **Metadata file**: `backend/app/data/faiss_index/metadata.pkl`

## Verifying the Index

### Check Index Stats
```bash
curl http://localhost:8000/api/v1/admin/stats
```

Response includes:
```json
{
  "vector_store": {
    "total_documents": 150,
    "total_vectors": 150,
    "dimension": 384,
    "model": "sentence-transformers/all-MiniLM-L6-v2"
  }
}
```

### Test Search
```bash
curl -X POST http://localhost:8000/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{"query": "How to grow wheat?"}'
```

## Updating the Knowledge Base

### Adding New Content

1. **Edit existing files** or create new `.txt` files in `knowledge_base/` directory
2. **Rebuild the index**:
   ```bash
   python scripts/build_vector_db.py
   ```

### Best Practices for Updates

- **Keep content focused**: Each file should cover a specific domain
- **Use clear headings**: Helps with chunking and retrieval
- **Include examples**: Real-world examples improve search quality
- **Update regularly**: Keep information current with latest practices
- **Regional variations**: Consider adding region-specific content

## Content Suggestions

### Crop Cultivation (`crop_cultivation.txt`)
- Crop-specific cultivation guides (wheat, rice, cotton, etc.)
- Sowing times and seasons
- Seed rates and spacing
- Irrigation schedules
- Fertilizer recommendations
- Harvesting methods
- Post-harvest management

### Pest Management (`pest_management.txt`)
- Common pests and their identification
- Disease symptoms and diagnosis
- Integrated Pest Management (IPM) strategies
- Chemical and biological control methods
- Economic threshold levels
- Safety guidelines
- Preventive measures

### Soil Health (`soil_health.txt`)
- Soil testing procedures
- Nutrient management
- pH correction methods
- Organic matter management
- Bio-fertilizers
- Soil conservation practices
- Soil health card information

### Farming Techniques (`farming_techniques.txt`)
- Modern irrigation methods (drip, sprinkler)
- Conservation agriculture
- Precision farming
- Organic farming practices
- Integrated farming systems
- Mechanization
- Water management

## Troubleshooting

### Empty Index
**Problem**: Index has 0 vectors
**Solution**: 
1. Check knowledge base files have content
2. Run build script: `python scripts/build_vector_db.py`
3. Check logs for errors

### Low Search Quality
**Problem**: Search results not relevant
**Solution**:
1. Improve knowledge base content quality
2. Add more specific information
3. Check similarity threshold in config (default: 0.3)
4. Increase top_k results (default: 5)

### Index Not Loading
**Problem**: Server fails to load index
**Solution**:
1. Check file permissions
2. Verify index file exists
3. Check disk space
4. Rebuild index if corrupted

### Memory Issues
**Problem**: Out of memory during indexing
**Solution**:
1. Process files in batches
2. Reduce chunk size
3. Use smaller embedding model
4. Increase system RAM

## Configuration

Edit `backend/app/config.py` to customize:

```python
# Vector Database Settings
EMBEDDING_MODEL: str = "sentence-transformers/all-MiniLM-L6-v2"
FAISS_INDEX_PATH: str = "./app/data/faiss_index/knowledge_base.index"
TOP_K_RESULTS: int = 5
SIMILARITY_THRESHOLD: float = 0.3
```

### Alternative Embedding Models

- `sentence-transformers/all-mpnet-base-v2` (768 dim, better quality)
- `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` (multilingual)
- `sentence-transformers/all-MiniLM-L12-v2` (384 dim, faster)

## Performance Tips

1. **Chunk Size**: Optimal chunk size is 300-500 characters
2. **Index Type**: Using `IndexFlatIP` for cosine similarity (good for <100K vectors)
3. **Batch Processing**: Process multiple files in parallel
4. **Caching**: Enable Redis cache for faster repeated queries

## Maintenance

### Regular Updates
- Update knowledge base quarterly
- Rebuild index after major content changes
- Monitor search quality metrics
- Collect user feedback

### Backup
- Backup index files regularly
- Version control knowledge base files
- Keep index metadata synchronized

## Additional Resources

- [FAISS Documentation](https://github.com/facebookresearch/faiss)
- [Sentence Transformers](https://www.sbert.net/)
- [RAG Best Practices](https://www.pinecone.io/learn/retrieval-augmented-generation/)

