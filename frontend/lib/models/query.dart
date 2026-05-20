import 'query_response.dart';

enum QueryType { voice, text, image }

enum QueryStatus { pending, answered, escalated, resolved }

class Query {
  Query({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = QueryStatus.pending,
    this.imagePath,
    this.context,
    this.response,
  });

  final String id;
  final String content;
  final QueryType type;
  final DateTime timestamp;
  final QueryStatus status;
  final String? imagePath;
  final Map<String, dynamic>? context;
  final QueryResponseModel? response;

  Query copyWith({
    QueryStatus? status,
    QueryResponseModel? response,
    Map<String, dynamic>? context,
  }) {
    return Query(
      id: id,
      content: content,
      type: type,
      timestamp: timestamp,
      status: status ?? this.status,
      imagePath: imagePath,
      context: context ?? this.context,
      response: response ?? this.response,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'type': type.toString(),
        'timestamp': timestamp.toIso8601String(),
        'status': status.toString(),
        'imagePath': imagePath,
        'context': context,
        'response': response?.toJson(),
      }..removeWhere((key, value) => value == null);

  factory Query.fromJson(Map<String, dynamic> json) => Query(
        id: json['id'],
        content: json['content'],
        type: QueryType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => QueryType.text,
        ),
        timestamp: DateTime.parse(json['timestamp']),
        status: QueryStatus.values.firstWhere(
          (e) => e.toString() == json['status'],
          orElse: () => QueryStatus.pending,
        ),
        imagePath: json['imagePath'],
        context: (json['context'] as Map<String, dynamic>?),
        response: json['response'] != null
            ? QueryResponseModel.fromJson(json['response'] as Map<String, dynamic>)
            : null,
      );
}
