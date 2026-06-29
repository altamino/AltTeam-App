// lib/core/network/requester.dart
import 'dart:convert';
import 'dart:typed_data'; // Добавлено для работы с Uint8List
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

  // Изменили dynamic data и добавили кастомные заголовки для проверки Content-Type
  Map<String, String> _buildHeaders({dynamic data, Map<String, String>? extraHeaders}) {
    final headers = Map<String, String>.from(basicHeaders);

    headers['NDCLANG'] = language;
    headers['User-Agent'] = userAgent;
    headers['NDCDEVICEID'] = deviceId;

    if (data != null) {
      if (data is Uint8List) {
        // Логика для бинарных данных (медиафайлы)
        headers['Content-Length'] = data.length.toString();
        // Если ваш генератор подписей принимает только строки, 
        // возможно, для файлов Amino требует подпись от HEX или вовсе её не требует.
        // Обычно для медиа используется: Generator.signature(data) или подпись опускается.
        headers['NDC-MSG-SIG'] = Generator.signature(data); 
      } else {
        // Логика для обычного JSON/Текста
        final encoded = data is String ? data : jsonEncode(data);
        headers['NDC-MSG-SIG'] = Generator.signature(encoded);
        headers['Content-Length'] = utf8.encode(encoded).length.toString();
      }
    }

    if (sid != null) {
      if (userId != null){
        headers['AUID'] = userId ?? "";
      }
      headers['NDCAUTH'] = 'sid=$sid';
    }

    // Накладываем extraHeaders ПЕРЕД тем как Dio сделает запрос,
    // чтобы кастомный Content-Type не затерся.
    if (extraHeaders != null) headers.addAll(extraHeaders);

    return headers;
  }

  Future<Map<String, dynamic>> request(
    String method,
    String endpoint, {
    dynamic body, // Изменено с Map<String, dynamic>? на dynamic
    Map<String, String>? extraHeaders,
    List<int> allowedCodes = const [200],
  }) async {
    // Внедряем timestamp только если это JSON-карта
    if (body is Map<String, dynamic>) {
      body['timestamp'] = Generator.reqTime();
    }

    // Передаем extraHeaders прямо в билдер заголовков
    final headers = _buildHeaders(data: body, extraHeaders: extraHeaders);

    final url = '$apiUrl$endpoint';
    debugPrint('[HTTP][REQ] $method $url');
    debugPrint('[HTTP][REQ] Headers: $headers');
    
    if (body != null && body is! Uint8List) {
      debugPrint('[REQ] Body: ${body is String ? body : jsonEncode(body)}');
    } else if (body is Uint8List) {
      debugPrint('[REQ] Body: <Binary Data: ${body.length} bytes>');
    }

    try {
      // Подготавливаем данные для Dio
      dynamic requestData;
      if (body is Uint8List) {
        requestData = body; // Для файлов передаем чистые байты
      } else if (body != null) {
        requestData = body is String ? body : jsonEncode(body); // Для JSON — строку
      }

      final response = await _dio.request(
        endpoint,
        data: requestData,
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

  // Обновляем сигнатуры шорткатов для поддержки динамических типов и кастомных хедеров

  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? headers}) =>
      request('GET', endpoint, extraHeaders: headers);

  Future<Map<String, dynamic>> post(String endpoint, {dynamic body, Map<String, String>? headers}) =>
      request('POST', endpoint, body: body, extraHeaders: headers);

  Future<Map<String, dynamic>> delete(String endpoint, {dynamic body, Map<String, String>? headers}) =>
      request('DELETE', endpoint, body: body, extraHeaders: headers);
}