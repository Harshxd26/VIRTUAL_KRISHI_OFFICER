class QueryResponseModel {
  QueryResponseModel({
    required this.queryId,
    required this.query,
    required this.answer,
    required this.intent,
    required this.confidence,
    required this.metadata,
    required this.timestamp,
    this.sources = const [],
    this.cached = false,
  });

  final String queryId;
  final String query;
  final String answer;
  final List<QuerySource> sources;
  final String intent;
  final double confidence;
  final QueryMetadata metadata;
  final bool cached;
  final DateTime timestamp;

  bool get shouldEscalate => confidence < 0.55;

  factory QueryResponseModel.fromJson(Map<String, dynamic> json) {
    return QueryResponseModel(
      queryId: json['query_id'] ?? '',
      query: json['query'] ?? '',
      answer: json['answer'] ?? '',
      sources: (json['sources'] as List<dynamic>? ?? [])
          .map((source) => QuerySource.fromJson(source as Map<String, dynamic>))
          .toList(),
      intent: json['intent'] ?? 'general',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      metadata: QueryMetadata.fromJson(json['metadata'] as Map<String, dynamic>? ?? const {}),
      cached: json['cached'] ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'query_id': queryId,
        'query': query,
        'answer': answer,
        'sources': sources.map((s) => s.toJson()).toList(),
        'intent': intent,
        'confidence': confidence,
        'metadata': metadata.toJson(),
        'cached': cached,
        'timestamp': timestamp.toIso8601String(),
      };
}

class QuerySource {
  QuerySource({
    required this.type,
    required this.title,
    this.content,
    this.url,
    this.score,
    this.metadata = const {},
  });

  final String type;
  final String title;
  final String? content;
  final String? url;
  final double? score;
  final Map<String, dynamic> metadata;

  factory QuerySource.fromJson(Map<String, dynamic> json) => QuerySource(
        type: json['type'] ?? '',
        title: json['title'] ?? '',
        content: json['content'],
        url: json['url'],
        score: (json['score'] as num?)?.toDouble(),
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'content': content,
        'url': url,
        'score': score,
        'metadata': metadata,
      }..removeWhere((key, value) => value == null);
}

class QueryMetadata {
  QueryMetadata({
    this.processingTimeSeconds = 0,
    this.sourcesUsed = 0,
    this.intentConfidence = 0,
    this.language = 'en',
    this.locationUsed = false,
  });

  final double processingTimeSeconds;
  final int sourcesUsed;
  final double intentConfidence;
  final String language;
  final bool locationUsed;

  factory QueryMetadata.fromJson(Map<String, dynamic> json) => QueryMetadata(
        processingTimeSeconds: (json['processing_time_seconds'] as num? ?? 0).toDouble(),
        sourcesUsed: (json['sources_used'] as num? ?? 0).toInt(),
        intentConfidence: (json['intent_confidence'] as num? ?? 0).toDouble(),
        language: json['language'] ?? 'en',
        locationUsed: json['location_used'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'processing_time_seconds': processingTimeSeconds,
        'sources_used': sourcesUsed,
        'intent_confidence': intentConfidence,
        'language': language,
        'location_used': locationUsed,
      };
}

