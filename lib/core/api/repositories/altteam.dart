import '../network/api.dart';

class AltTemRepository {
  Future<void> reset_password_by_email(String email) async {
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


}