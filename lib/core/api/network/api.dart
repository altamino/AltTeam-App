import 'dart:typed_data'; // Добавлено для поддержки отправки байтов (медиа)
import '../helpers/generator.dart';
import 'requester.dart';
import '../../storage.dart';
import '../constants.dart';

class Api {
  static late final Requester _requester;

  static Future<void> init() async {
    var deviceId = Storage.deviceId;
    if (deviceId == null) {
      deviceId = Generator.genDeviceId();
      await Storage.setDeviceId(deviceId);
    }

    _requester = Requester(
      userAgent: UserAgent,
      deviceId: deviceId,
    );

    final sid = Storage.sid;
    final userId = Storage.userId;
    if (sid != null && userId != null) {
      _requester.sid = sid;
      _requester.userId = userId;
    }
  }

  // GET теперь принимает опциональные заголовки
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
  }) =>
      _requester.get(endpoint, headers: headers);

  // В POST изменен тип body на dynamic (чтобы слать Map или Uint8List) и добавлены headers
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) =>
      _requester.post(endpoint, body: body, headers: headers);

  // В DELETE добавлены опциональные заголовки
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) =>
      _requester.delete(endpoint, body: body, headers: headers);

  static void setSid(String sid, userId, role) {
    Storage.setSid(sid);
    Storage.setUserId(userId);
    Storage.setRole(role);
    _requester.sid = sid;
    _requester.userId = userId;
  }

  static String getDeviceId() {
    return _requester.deviceId ?? Generator.genDeviceId();
  }

  static void clearSession() {
    _requester.sid = null;
    _requester.userId = null;
    Storage.clearSession();
  }
}