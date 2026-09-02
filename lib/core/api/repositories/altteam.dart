import '../network/api.dart';

class AltTemRepository {

  Future<void> resetPasswordByEmail(String email) async {
    await Api.post('/g/s/altteam/reset-password', body: {
      "email": email
    });
  }

  Future<Map<String, dynamic>> getReports({
    required String segment,
    required int start,
    required int size,
    required String pageToken,
  }) async {
    final resolvedSegment = segment.isEmpty ? 'all' : segment;

    final path = '/g/s/altteam/reports'
        '?segment=${Uri.encodeComponent(resolvedSegment)}'
        '&start=$start'
        '&size=$size'
        '&pageToken=${Uri.encodeComponent(pageToken)}';

    return await Api.get(path);
  }

  Future<Map<String, dynamic>> getTeam() async {
    return await Api.get('/g/s/altteam');
  }


  Future<void> editTeamMember({
    required String userId,
    int? role,
    List<String>? tagList,
    bool? isMemberOfTeamAmino,
    bool? isVerified,
  }) async {
    await Api.post('/g/s/altteam/$userId/edit', body: {
      if (role != null) "role": role,
      if (tagList != null) "tagList": tagList,
      if (isMemberOfTeamAmino != null) "isMemberOfTeamAmino": isMemberOfTeamAmino,
      if (isVerified != null) "isVerified": isVerified,
    });
  }

  Future<void> setUserStatus({required String userId, required int status}) async {
    await Api.post('/g/s/altteam/user-profile/$userId/status', body: {
      "status": status,
    });
  }

  Future<Map<String, dynamic>> getUserCommunities(String userId) async {
    return await Api.get('/g/s/altteam/user-profile/$userId/communities');
  }


  Future<void> setModerationStatus({
    required String type, // 'user' or 'community' ect
    required String objId,
    required bool disable,
  }) async {
    final action = disable ? 'disable' : 'enable';
    await Api.post('/g/s/altteam/mod/$type/$action/$objId');
  }

}