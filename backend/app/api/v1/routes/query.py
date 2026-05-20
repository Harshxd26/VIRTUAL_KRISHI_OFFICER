"""
Query Endpoint - Main API route for processing agricultural queries
Handles classification, retrieval, external data fetching, and LLM reasoning
"""

from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends
from typing import Optional
import asyncio
from datetime import datetime

from app.models.request_models import QueryRequest
from app.models.response_models import QueryResponse, Source
from app.core.classifier import QueryClassifier
from app.core.context_builder import ContextBuilder
from app.core.post_processor import PostProcessor
from app.core.cache import cache_manager
from app.services.retrieval.vector_store import vector_store
from app.services.retrieval.structured_db import db_manager
from app.services.external.weather import weather_service
from app.services.external.market_prices import market_service
from app.services.external.schemes import scheme_service
from app.services.llm.ollama_client import llm_client
from app.utils.logger import setup_logging
from app.api.v1.middleware.rate_limit import rate_limit_dependency

logger = setup_logging()
router = APIRouter()

# Initialize components
classifier = QueryClassifier()
context_builder = ContextBuilder()
post_processor = PostProcessor()


@router.post("/query", response_model=QueryResponse)
async def process_query(
    request: QueryRequest,
    background_tasks: BackgroundTasks,
    _: None = Depends(rate_limit_dependency)
):
    """
    Main query processing endpoint
    
    Flow:
    1. Classify query intent
    2. Retrieve relevant knowledge from vector DB
    3. Fetch external data (weather, prices, schemes)
    4. Build context and generate response with LLM
    5. Post-process and validate response
    6. Cache result
    """
    start_time = datetime.now()
    query_id = f"q_{int(start_time.timestamp() * 1000)}"
    
    logger.info(f"🔍 Processing query {query_id}: {request.query[:100]}...")
    
    try:
        # Step 1: Check cache
        cache_key = f"query:{request.query}:{request.latitude}:{request.longitude}"
        cached_response = await cache_manager.get(cache_key)
        
        if cached_response:
            logger.info(f"✅ Cache hit for query {query_id}")
            return QueryResponse(**cached_response, cached=True)
        
        # Step 2: Classify query intent
        intent = await classifier.classify(request.query)
        logger.info(f"📊 Query intent: {intent.primary_intent} (confidence: {intent.confidence:.2f})")
        
        # Step 3: Parallel data retrieval
        retrieval_tasks = []
        
        # 3a. Vector search for relevant knowledge
        retrieval_tasks.append(
            vector_store.search(request.query, top_k=5)
        )
        
        # 3b. Structured database queries (based on intent)
        if intent.requires_crop_data:
            retrieval_tasks.append(
                db_manager.get_crop_info(intent.extracted_entities.get('crop'))
            )
        
        # 3c. Weather data (if location provided)
        if request.latitude and request.longitude:
            retrieval_tasks.append(
                weather_service.get_forecast(
                    latitude=request.latitude, 
                    longitude=request.longitude,
                    days=7
                )
            )
        
        # 3d. Market prices (if intent related to prices)
        if intent.requires_market_data:
            retrieval_tasks.append(
                market_service.get_prices(
                    commodity=intent.extracted_entities.get('commodity'),
                    state=request.state
                )
            )
        
        # 3e. Government schemes (if applicable)
        if intent.requires_scheme_info:
            retrieval_tasks.append(
                scheme_service.search_schemes(request.query)
            )
        
        # Execute all retrieval tasks in parallel
        retrieval_results = await asyncio.gather(*retrieval_tasks, return_exceptions=True)
        
        # Step 4: Build context from retrieved data
        context = await context_builder.build(
            query=request.query,
            intent=intent,
            retrieval_results=retrieval_results,
            user_location={
                "latitude": request.latitude,
                "longitude": request.longitude,
                "state": request.state,
                "district": request.district
            }
        )
        
        logger.info(f"📚 Context built: {len(context.sources)} sources, {len(context.text)} chars")
        
        # Step 5: Generate response with LLM
        llm_response = await llm_client.generate(
            query=request.query,
            context=context.text,
            intent=intent.primary_intent,
            language=request.language or "en"
        )
        
        logger.info(f"🤖 LLM response generated: {len(llm_response)} chars")
        
        # Step 6: Post-process response
        processed_response = await post_processor.process(
            response_text=llm_response,
            context=context,
            intent=intent
        )
        
        # Step 7: Build final response
        processing_time = (datetime.now() - start_time).total_seconds()
        
        response = QueryResponse(
            query_id=query_id,
            query=request.query,
            answer=processed_response.answer,
            sources=context.sources,
            intent=intent.primary_intent,
            confidence=intent.confidence,
            metadata={
                "processing_time_seconds": processing_time,
                "sources_used": len(context.sources),
                "intent_confidence": intent.confidence,
                "language": request.language or "en",
                "location_used": bool(request.latitude and request.longitude)
            },
            cached=False,
            timestamp=datetime.now()
        )
        
        # Step 8: Cache response (background task)
        background_tasks.add_task(
            cache_manager.set,
            cache_key,
            response.dict(),
            ttl=3600  # 1 hour
        )
        
        # Step 9: Log analytics (background task)
        background_tasks.add_task(
            log_query_analytics,
            query_id=query_id,
            intent=intent.primary_intent,
            processing_time=processing_time,
            sources_count=len(context.sources)
        )
        
        logger.info(f"✅ Query {query_id} completed in {processing_time:.2f}s")
        
        return response
        
    except Exception as e:
        logger.error(f"❌ Error processing query {query_id}: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail={
                "query_id": query_id,
                "error": "Failed to process query",
                "message": str(e)
            }
        )


@router.post("/query/batch")
async def process_batch_queries(
    queries: list[QueryRequest],
    _: None = Depends(rate_limit_dependency)
):
    """Process multiple queries in batch (max 5 at a time)"""
    if len(queries) > 5:
        raise HTTPException(
            status_code=400,
            detail="Maximum 5 queries allowed per batch"
        )
    
    tasks = [process_query(query, BackgroundTasks()) for query in queries]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    return {
        "results": [
            result if not isinstance(result, Exception) else {"error": str(result)}
            for result in results
        ]
    }


@router.get("/intents")
async def get_available_intents():
    """Get list of supported query intents"""
    return {
        "intents": [
            {
                "name": "crop_cultivation",
                "description": "Questions about growing crops",
                "examples": [
                    "How to grow wheat?",
                    "Best time to plant tomatoes?"
                ]
            },
            {
                "name": "pest_management",
                "description": "Pest and disease identification and treatment",
                "examples": [
                    "How to control aphids?",
                    "My wheat has yellow rust"
                ]
            },
            {
                "name": "weather_query",
                "description": "Weather forecasts and agricultural advisories",
                "examples": [
                    "Will it rain this week?",
                    "Is it good time for sowing?"
                ]
            },
            {
                "name": "market_prices",
                "description": "Current market rates for crops",
                "examples": [
                    "What is wheat price today?",
                    "Best place to sell tomatoes?"
                ]
            },
            {
                "name": "government_schemes",
                "description": "Information about agricultural schemes",
                "examples": [
                    "How to apply for PM-KISAN?",
                    "What is Kisan Credit Card?"
                ]
            },
            {
                "name": "soil_health",
                "description": "Soil testing and improvement",
                "examples": [
                    "How to improve soil fertility?",
                    "What is soil health card?"
                ]
            }
        ]
    }


async def log_query_analytics(
    query_id: str,
    intent: str,
    processing_time: float,
    sources_count: int
):
    """Log query analytics for monitoring"""
    try:
        # This could be sent to analytics service, database, or log file
        analytics_data = {
            "query_id": query_id,
            "intent": intent,
            "processing_time": processing_time,
            "sources_count": sources_count,
            "timestamp": datetime.now().isoformat()
        }
        logger.info(f"📊 Analytics: {analytics_data}")
    except Exception as e:
        logger.error(f"Failed to log analytics: {e}")