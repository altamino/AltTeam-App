import '../network/api.dart';

class UsersRepository {
  Future<Map<String, dynamic>> get_user_profile(String userId, int ndcId) async {
    final res = await Api.get('/x${ndcId}/s/user-profile/${userId}');
    return (res['userProfile'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> getAltTeam() async {
    final res = await Api.get('/g/s/altteam');
    final list = res['userProfileList'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }


}