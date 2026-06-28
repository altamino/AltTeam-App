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


  static Future<Map<String, dynamic>> get(String endpoint) =>
      _requester.get(endpoint);

  static Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) =>
      _requester.post(endpoint, body: body);

  static Future<Map<String, dynamic>> delete(String endpoint, {Map<String, dynamic>? body}) =>
      _requester.delete(endpoint, body: body);

  static void setSid(String sid, String userId) {
    Storage.setSid(sid);
    Storage.setUserId(userId);
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