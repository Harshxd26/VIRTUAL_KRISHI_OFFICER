import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/query_request.dart';
import '../models/query_response.dart';
import 'dart:io';

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<QueryResponseModel> sendQuery(QueryRequest payload) async {
    final uri = _resolve('/chat');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return QueryResponseModel.fromJson(data);
    }

    throw ApiException.fromHttpResponse(response);
  }

  Future<QueryResponseModel> sendImage(File imageFile) async {
    final uri = _resolve('/analyze-image');

    final request = http.MultipartRequest('POST', uri);

    // attach image file
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // MUST match FastAPI parameter name
        imageFile.path,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return QueryResponseModel.fromJson(data);
    }

    throw ApiException.fromHttpResponse(response);
  }

  void dispose() {
    _client.close();
  }

  Uri _resolve(String path) {
    final trimmedBase = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$trimmedBase$normalizedPath');
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  factory ApiException.fromHttpResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiException(
        data['message']?.toString() ?? 'Failed to process query',
        statusCode: response.statusCode,
        details: data,
      );
    } catch (_) {
      return ApiException(
        'Failed to process query',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
