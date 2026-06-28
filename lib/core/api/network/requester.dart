// lib/core/network/requester.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../helpers/generator.dart';
import 'exceptions.dart';
import '../constants.dart';
import 'package:flutter/foundation.dart';

class Requester {
  final String userAgent;
  final String deviceId;
  final String language;
  String? sid;
  String? userId;

  late final Dio _dio;

  Requester({
    required this.deviceId,
    this.userAgent = UserAgent,
    this.language = 'en',
    this.sid,
    this.userId,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: apiUrl,
      responseType: ResponseType.json,
      validateStatus: (_) => true,
    ));
  }

  Map<String, String> _buildHeaders({dynamic data}) {
    final headers = Map<String, String>.from(basicHeaders);

    headers['NDCLANG'] = language;
    headers['User-Agent'] = userAgent;
    headers['NDCDEVICEID'] = deviceId;

    if (data != null) {
      final encoded = data is String ? data : jsonEncode(data);
      headers['NDC-MSG-SIG'] = Generator.signature(encoded);
      headers['Content-Length'] = utf8.encode(encoded).length.toString();
    }

    if (sid != null) {
      if (userId != null){
        headers['AUID'] = userId ?? "";
      }
      headers['NDCAUTH'] = 'sid=$sid';
    }

    return headers;
  }

Future<Map<String, dynamic>> request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
    List<int> allowedCodes = const [200],
  }) async {
    if (body != null) {
      body['timestamp'] = Generator.reqTime();
    }

    final headers = _buildHeaders(data: body);
    if (extraHeaders != null) headers.addAll(extraHeaders);

    final url = '$apiUrl$endpoint';
    debugPrint('[HTTP][REQ] $method $url');
    debugPrint('[HTTP][REQ] Headers: $headers');
    if (body != null) debugPrint('[REQ] Body: ${jsonEncode(body)}');

    try {
      final response = await _dio.request(
        endpoint,
        data: body != null ? jsonEncode(body) : null,
        options: Options(method: method, headers: headers),
      );

      debugPrint('[HTTP][RES] ${response.statusCode} $url');
      debugPrint('[HTTP][RES] Body: ${response.data}');

      if (!allowedCodes.contains(response.statusCode)) {
        debugPrint('[HTTP][RES] ❌ Unexpected status: ${response.statusCode}');
        _checkException(response);
      }

      return response.data is Map<String, dynamic>
          ? response.data
          : {'data': response.data};
    } on DioException catch (e) {
      debugPrint('[HTTP][ERR] DioException: ${e.message}');
      debugPrint('[HTTP][ERR] Type: ${e.type}');
      throw NetworkException(message: e.message ?? 'Network error');
    }
  }

  void _checkException(Response response) {
    final data = response.data;
    final code = data?['api:statuscode']?.toString() ?? 'unknown';
    final message = data?['api:message']?.toString() ?? 'Unknown error';

    if (response.statusCode == 401) {
      throw UnauthorizedException(code: code, message: message);
    }

    throw ApiException(
      code: code,
      message: message,
      statusCode: response.statusCode,
    );
  }

  // ─── Shortcuts ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(String endpoint) =>
      request('GET', endpoint);

  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) =>
      request('POST', endpoint, body: body ?? {});

  Future<Map<String, dynamic>> delete(String endpoint, {Map<String, dynamic>? body}) =>
      request('DELETE', endpoint, body: body);
}