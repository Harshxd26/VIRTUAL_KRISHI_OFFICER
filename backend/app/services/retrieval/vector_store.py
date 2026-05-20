"""
Vector Store Service - FAISS-based semantic search
Handles embedding generation and similarity search for RAG
"""

import faiss
import numpy as np
from sentence_transformers import SentenceTransformer
from typing import List, Dict, Optional
import pickle
import os
from pathlib import Path

from app.config import settings
from app.utils.logger import setup_logging

logger = setup_logging()


class VectorStore:
    """FAISS vector store for semantic search"""
    
    def __init__(self):
        self.model_name = settings.EMBEDDING_MODEL
        self.index_path = Path(settings.FAISS_INDEX_PATH)
        self.metadata_path = self.index_path.parent / "metadata.pkl"
        
        self.model: Optional[SentenceTransformer] = None
        self.index: Optional[faiss.Index] = None
        self.documents: List[Dict] = []
        self.dimension: int = 384  # Default for all-MiniLM-L6-v2
    
    async def initialize(self):
        """Initialize the vector store"""
        try:
            # Load embedding model
            logger.info(f"Loading embedding model: {self.model_name}")
            self.model = SentenceTransformer(self.model_name)
            self.dimension = self.model.get_sentence_embedding_dimension()
            logger.info(f"✅ Embedding model loaded (dimension: {self.dimension})")
            
            # Load or create FAISS index
            if self.index_path.exists():
                self._load_index()
            else:
                logger.warning("No existing index found. Creating empty index...")
                self._create_index()
                
        except Exception as e:
            logger.error(f"❌ Failed to initialize vector store: {e}")
            raise
    
    def _create_index(self):
        """Create a new FAISS index"""
        # Use IndexFlatIP for cosine similarity (after normalization)
        self.index = faiss.IndexFlatIP(self.dimension)
        self.documents = []
        logger.info("✅ Created new FAISS index")
    
    def _load_index(self):
        """Load existing FAISS index and metadata"""
        try:
            self.index = faiss.read_index(str(self.index_path))
            
            if self.metadata_path.exists():
                with open(self.metadata_path, 'rb') as f:
                    self.documents = pickle.load(f)
            
            logger.info(f"✅ Loaded FAISS index with {self.index.ntotal} vectors")
            
        except Exception as e:
            logger.error(f"Failed to load index: {e}")
            self._create_index()
    
    def _save_index(self):
        """Save FAISS index and metadata"""
        try:
            self.index_path.parent.mkdir(parents=True, exist_ok=True)
            
            faiss.write_index(self.index, str(self.index_path))
            
            with open(self.metadata_path, 'wb') as f:
                pickle.dump(self.documents, f)
            
            logger.info(f"✅ Saved FAISS index with {self.index.ntotal} vectors")
            
        except Exception as e:
            logger.error(f"Failed to save index: {e}")
    
    async def add_documents(self, documents: List[Dict]):
        """
        Add documents to the vector store
        
        Args:
            documents: List of dicts with 'text', 'metadata', etc.
        """
        if not documents:
            return
        
        try:
            # Extract texts
            texts = [doc['text'] for doc in documents]
            
            # Generate embeddings
            logger.info(f"Generating embeddings for {len(texts)} documents...")
            embeddings = self.model.encode(
                texts,
                batch_size=32,
                show_progress_bar=True,
                normalize_embeddings=True  # For cosine similarity
            )
            
            # Add to FAISS index
            self.index.add(embeddings.astype('float32'))
            
            # Store metadata
            self.documents.extend(documents)
            
            # Save
            self._save_index()
            
            logger.info(f"✅ Added {len(documents)} documents to vector store")
            
        except Exception as e:
            logger.error(f"Failed to add documents: {e}")
            raise
    
    async def search(
        self,
        query: str,
        top_k: int = 5,
        score_threshold: float = 0.3
    ) -> List[Dict]:
        """
        Search for similar documents
        
        Args:
            query: Search query
            top_k: Number of results to return
            score_threshold: Minimum similarity score (0-1)
        
        Returns:
            List of relevant documents with scores
        """
        try:
            if self.index.ntotal == 0:
                logger.warning("Vector store is empty")
                return []
            
            # Generate query embedding
            query_embedding = self.model.encode(
                [query],
                normalize_embeddings=True
            ).astype('float32')
            
            # Search
            scores, indices = self.index.search(query_embedding, min(top_k, self.index.ntotal))
            
            # Filter and format results
            results = []
            for score, idx in zip(scores[0], indices[0]):
                if score >= score_threshold and idx < len(self.documents):
                    result = self.documents[idx].copy()
                    result['score'] = float(score)
                    results.append(result)
            
            logger.info(f"Found {len(results)} relevant documents for query")
            return results
            
        except Exception as e:
            logger.error(f"Search failed: {e}")
            return []
    
    async def search_with_filter(
        self,
        query: str,
        filters: Dict,
        top_k: int = 5
    ) -> List[Dict]:
        """
        Search with metadata filters
        
        Args:
            query: Search query
            filters: Dict of metadata filters (e.g., {'category': 'pest_management'})
            top_k: Number of results
        """
        # Get more results initially for filtering
        results = await self.search(query, top_k=top_k * 3)
        
        # Apply filters
        filtered = []
        for result in results:
            metadata = result.get('metadata', {})
            if all(metadata.get(k) == v for k, v in filters.items()):
                filtered.append(result)
                if len(filtered) >= top_k:
                    break
        
        return filtered
    
    def get_stats(self) -> Dict:
        """Get vector store statistics"""
        return {
            "total_documents": len(self.documents),
            "total_vectors": self.index.ntotal if self.index else 0,
            "dimension": self.dimension,
            "model": self.model_name,
            "index_path": str(self.index_path)
        }


# Global instance
vector_store = VectorStore()


# Utility function for building index from files
async def build_index_from_directory(data_dir: str):
    """
    Build FAISS index from text files in a directory
    Used by scripts/build_vector_db.py
    """
    documents = []
    data_path = Path(data_dir)
    
    logger.info(f"Building index from {data_dir}")
    
    # Process all text files
    for file_path in data_path.glob("**/*.txt"):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Split into chunks (simple sentence-based splitting)
            chunks = _split_into_chunks(content, max_length=500)
            
            for i, chunk in enumerate(chunks):
                documents.append({
                    'text': chunk,
                    'metadata': {
                        'source': file_path.name,
                        'category': file_path.stem,
                        'chunk_id': i
                    }
                })
            
            logger.info(f"Processed {file_path.name}: {len(chunks)} chunks")
            
        except Exception as e:
            logger.error(f"Failed to process {file_path}: {e}")
    
    # Add to vector store
    if documents:
        await vector_store.initialize()
        await vector_store.add_documents(documents)
        logger.info(f"✅ Built index with {len(documents)} chunks from {data_dir}")
    else:
        logger.warning("No documents found to index")


def _split_into_chunks(text: str, max_length: int = 500) -> List[str]:
    """
    Split text into chunks while preserving sentence boundaries
    """
    # Simple sentence splitting (can be improved with NLTK)
    sentences = text.replace('\n', ' ').split('. ')
    
    chunks = []
    current_chunk = []
    current_length = 0
    
    for sentence in sentences:
        sentence = sentence.strip()
        if not sentence:
            continue
        
        sentence_length = len(sentence)
        
        if current_length + sentence_length > max_length and current_chunk:
            # Save current chunk
            chunks.append('. '.join(current_chunk) + '.')
            current_chunk = [sentence]
            current_length = sentence_length
        else:
            current_chunk.append(sentence)
            current_length += sentence_length
    
    # Add remaining chunk
    if current_chunk:
        chunks.append('. '.join(current_chunk) + '.')
    
    return chunks