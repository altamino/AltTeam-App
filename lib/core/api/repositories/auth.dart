import '../network/api.dart';

class AuthRepository {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await Api.post('/g/s/auth/login', body: {
      'email': email,
      'v': 2,
      'secret': '0 $password',
      'deviceID': Api.getDeviceId(),
      'clientType': 100,
      'action': 'normal',
    });
    if (res['sid'] != null) {
      Api.setSid(res['sid'], res['auid'], res['userProfile']?['role']);
    }
    return res;
  }

  Future<void> logout() async {
    try {
      await Api.post('/g/s/auth/logout');
    } catch (e) {
      
    } finally {
      Api.clearSession();
    }
  }
}