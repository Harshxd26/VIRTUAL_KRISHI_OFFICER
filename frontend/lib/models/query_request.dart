class QueryRequest {
  QueryRequest({
    required this.query,
    this.latitude,
    this.longitude,
    this.state,
    this.district,
    this.language = 'en',
    this.userId,
    this.context,
  });

  final String query;
  final double? latitude;
  final double? longitude;
  final String? state;
  final String? district;
  final String language;
  final String? userId;
  final Map<String, dynamic>? context;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'question': query,
      'latitude': latitude,
      'longitude': longitude,
      'state': state,
      'district': district,
      'language': language,
      'user_id': userId,
      'context': context,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}

