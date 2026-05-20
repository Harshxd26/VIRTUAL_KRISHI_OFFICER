# Backend API Routes Summary

## Base URL
- Development: `http://localhost:8000`
- Production: Configure via `HOST` and `PORT` in `config.py`

## Available Endpoints

### Root Endpoints

#### `GET /`
Root endpoint with API information
- **Response**: API name, version, status, available endpoints
- **Example**: `curl http://localhost:8000/`

#### `GET /metrics`
Prometheus-compatible metrics endpoint
- **Response**: System metrics
- **Example**: `curl http://localhost:8000/metrics`

### Health Check Endpoints (`/health`)

#### `GET /health/`
Basic health check
- **Response**: `HealthResponse` with status, version, environment
- **Example**: `curl http://localhost:8000/health/`

#### `GET /health/detailed`
Detailed health check with service status
- **Response**: `HealthResponse` with status of all services (vector_store, database, cache, LLM)
- **Example**: `curl http://localhost:8000/health/detailed`

#### `GET /health/ready`
Kubernetes readiness probe
- **Response**: `{"ready": true}`
- **Example**: `curl http://localhost:8000/health/ready`

#### `GET /health/live`
Kubernetes liveness probe
- **Response**: `{"alive": true}`
- **Example**: `curl http://localhost:8000/health/live`

### Query Endpoints (`/api/v1`)

#### `POST /api/v1/query`
Main query processing endpoint
- **Request Body**: `QueryRequest`
  ```json
  {
    "query": "How to grow wheat?",
    "latitude": 28.7041,
    "longitude": 77.1025,
    "state": "Delhi",
    "district": "New Delhi",
    "language": "en"
  }
  ```
- **Response**: `QueryResponse` with answer, sources, intent, confidence
- **Example**: 
  ```bash
  curl -X POST http://localhost:8000/api/v1/query \
    -H "Content-Type: application/json" \
    -d '{"query": "How to grow wheat?"}'
  ```

#### `POST /api/v1/query/batch`
Process multiple queries in batch (max 5)
- **Request Body**: Array of `QueryRequest`
- **Response**: Array of results
- **Example**:
  ```bash
  curl -X POST http://localhost:8000/api/v1/query/batch \
    -H "Content-Type: application/json" \
    -d '[{"query": "How to grow wheat?"}, {"query": "What is the price of rice?"}]'
  ```

#### `GET /api/v1/intents`
Get list of supported query intents
- **Response**: List of intents with descriptions and examples
- **Example**: `curl http://localhost:8000/api/v1/intents`

### Admin Endpoints (`/api/v1/admin`)

#### `GET /api/v1/admin/stats`
Get system statistics
- **Response**: Statistics for vector_store, cache, database, metrics
- **Example**: `curl http://localhost:8000/api/v1/admin/stats`

#### `POST /api/v1/admin/cache/clear`
Clear application cache
- **Response**: `{"message": "Cache cleared successfully"}`
- **Example**: 
  ```bash
  curl -X POST http://localhost:8000/api/v1/admin/cache/clear
  ```

#### `GET /api/v1/admin/config`
Get current configuration (non-sensitive)
- **Response**: App name, version, features, LLM configuration
- **Example**: `curl http://localhost:8000/api/v1/admin/config`

#### `POST /api/v1/admin/rebuild-index`
Rebuild FAISS vector index from knowledge base files
- **Response**: Success message and index statistics
- **Example**:
  ```bash
  curl -X POST http://localhost:8000/api/v1/admin/rebuild-index
  ```

## API Documentation

### Swagger UI (Development Only)
- **URL**: `http://localhost:8000/docs`
- **Description**: Interactive API documentation
- **Note**: Only available when `DEBUG=True`

### ReDoc (Development Only)
- **URL**: `http://localhost:8000/redoc`
- **Description**: Alternative API documentation
- **Note**: Only available when `DEBUG=True`

## Request/Response Models

### QueryRequest
```json
{
  "query": "string (3-500 chars, required)",
  "latitude": "float (optional, -90 to 90)",
  "longitude": "float (optional, -180 to 180)",
  "state": "string (optional, max 100 chars)",
  "district": "string (optional, max 100 chars)",
  "language": "string (optional, default: 'en')",
  "user_id": "string (optional)",
  "context": "object (optional)"
}
```

### QueryResponse
```json
{
  "query_id": "string",
  "query": "string",
  "answer": "string",
  "sources": [
    {
      "type": "string",
      "title": "string",
      "content": "string (optional)",
      "url": "string (optional)",
      "score": "float (optional, 0-1)"
    }
  ],
  "intent": "string",
  "confidence": "float (0-1)",
  "metadata": {
    "processing_time_seconds": "float",
    "sources_used": "integer",
    "intent_confidence": "float",
    "language": "string",
    "location_used": "boolean"
  },
  "cached": "boolean",
  "timestamp": "datetime"
}
```

### HealthResponse
```json
{
  "status": "string (healthy/degraded)",
  "version": "string",
  "environment": "string",
  "timestamp": "datetime",
  "services": {
    "vector_store": "boolean",
    "database": "boolean",
    "cache": "boolean",
    "llm": "boolean"
  }
}
```

## Error Responses

### Standard Error Format
```json
{
  "success": false,
  "error": "string",
  "message": "string",
  "query_id": "string (optional)",
  "timestamp": "datetime"
}
```

### HTTP Status Codes
- `200 OK`: Successful request
- `400 Bad Request`: Invalid request data
- `404 Not Found`: Resource not found
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

## Rate Limiting

- **Per Minute**: 20 requests (configurable via `RATE_LIMIT_PER_MINUTE`)
- **Per Hour**: 500 requests (configurable via `RATE_LIMIT_PER_HOUR`)
- **Headers**: Rate limit info in response headers

## CORS

- **Allowed Origins**: `*` (all origins)
- **Allowed Methods**: `*` (all methods)
- **Allowed Headers**: `*` (all headers)
- **Credentials**: Enabled

## Testing Endpoints

### Quick Health Check
```bash
curl http://localhost:8000/health/
```

### Test Query
```bash
curl -X POST http://localhost:8000/api/v1/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is the best time to plant wheat?",
    "latitude": 28.7041,
    "longitude": 77.1025,
    "state": "Delhi"
  }'
```

### Check System Stats
```bash
curl http://localhost:8000/api/v1/admin/stats
```

### Rebuild Index
```bash
curl -X POST http://localhost:8000/api/v1/admin/rebuild-index
```

## Notes

1. All endpoints return JSON responses
2. Timestamps are in ISO 8601 format
3. Error responses follow standard format
4. Rate limiting applies to query endpoints
5. Cache is enabled by default (1 hour TTL)
6. Vector search requires populated FAISS index
7. LLM responses depend on Ollama or Groq configuration

