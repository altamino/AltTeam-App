import '../network/api.dart';

class CommunitiesRepository {

  Future<Map<String, dynamic>> getCommunityInfo(int ndcId) async {
    return await Api.get('/x$ndcId/s/community/info');
  }

}