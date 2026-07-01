
import 'dart:convert';
import 'dart:typed_data'; 
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


  Map<String, String> _buildHeaders({dynamic data, Map<String, String>? extraHeaders}) {
    final headers = Map<String, String>.from(basicHeaders);

    headers['NDCLANG'] = language;
    headers['User-Agent'] = userAgent;
    headers['NDCDEVICEID'] = deviceId;

    if (data != null) {
      if (data is Uint8List) {

        headers['Content-Length'] = data.length.toString();

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


    if (extraHeaders != null) headers.addAll(extraHeaders);

    return headers;
  }

Future<Map<String, dynamic>> request(
  String method,
  String endpoint, {
  dynamic body,
  Map<String, String>? extraHeaders,
  List<int> allowedCodes = const [200],
}) async {
  if (body is Map<String, dynamic>) {
    body = {
      ...body,
      'timestamp': Generator.reqTime(),
    };
  }

  final encodedBody = body is String
      ? body
      : body != null
          ? jsonEncode(body)
          : null;

  final headers = _buildHeaders(data: encodedBody, extraHeaders: extraHeaders);

  final response = await _dio.request(
    endpoint,
    data: encodedBody,
    options: Options(method: method, headers: headers),
  );

  if (!allowedCodes.contains(response.statusCode)) {
    _checkException(response);
  }

  return response.data is Map<String, dynamic>
      ? response.data
      : {'data': response.data};
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

  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? headers}) =>
      request('GET', endpoint, extraHeaders: headers);

  Future<Map<String, dynamic>> post(String endpoint, {dynamic body, Map<String, String>? headers}) =>
      request('POST', endpoint, body: body, extraHeaders: headers);

  Future<Map<String, dynamic>> delete(String endpoint, {dynamic body, Map<String, String>? headers}) =>
      request('DELETE', endpoint, body: body, extraHeaders: headers);
}