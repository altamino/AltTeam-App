import '../network/api.dart';

class UsersRepository {
  Future<Map<String, dynamic>> getUserProfile(String userId, int ndcId) async {
    final res = await Api.get('/${(ndcId == 0) ? 'g' : 'x$ndcId'}/s/user-profile/${userId}');
    return (res['userProfile'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> getAltTeam() async {
    final res = await Api.get('/g/s/altteam');
    final list = res['userProfileList'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }





Future<Map<String, dynamic>> banUser({
    String? userId,
    int? ndcId,
    String? reason,
    int? banType,
  }) async {

    final Map<String, dynamic> data = {
      if (banType != null) "reasonType": banType,
      "note": {
        "content": reason ?? "No reason provided.",
      },
    };

    final res = await Api.post(
      '/${(ndcId == 0) ? 'g' : 'x$ndcId'}/s/user-profile/$userId/ban',
      body: data,
    );
    
    return (res as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> unbanUser({
    String? userId,
    int? ndcId,
    String? reason,
  }) async {

    
    final Map<String, dynamic> data = {
      "note": {
        "content": reason ?? "No reason provided.",
      },
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    final res = await Api.post(
      '/${(ndcId == 0) ? 'g' : 'x$ndcId'}/s/user-profile/$userId/unban',
      body: data,
    );

    return (res as Map<String, dynamic>?) ?? <String, dynamic>{};
  }
}