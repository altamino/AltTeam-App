import '../network/api.dart';

class UsersRepository {
  Future<Map<String, dynamic>> get_user_profile(String userId, int ndcId) async {
    final res = await Api.get('/x${ndcId}/s/user-profile/${userId}');
    return (res['userProfile'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }
}