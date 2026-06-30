import '../network/api.dart';

class AltACMRepository {
  Future<void> unpromoteUser(String userId, int ndcId) async {
    await Api.delete('/altacm/s/community/x${ndcId}/user/${userId}/promote');
  }
  Future<void> promoteUser(String userId, int ndcId, role) async {
    await Api.post('/altacm/s/community/x${ndcId}/user/${userId}/promote', body: {
      "role": role
    });
  }

  Future<Map<String, dynamic>> createCommunity(String name, aminoId, lang, String? agentGlobalLink) async {
    return await Api.post('/altacm/s/community/create', body: {
			"name": name,
			"aminoId": aminoId,
			"agentGlobalLink": agentGlobalLink,
			"lang": lang
		});
  }  

  Future<void> deleteCommunity(int ndcId) async {
    await Api.delete('/altacm/s/community/x${ndcId}/destroy');
  }


  Future<Map<String, dynamic>> getUserManagedCommunities(String userId) async {
    return await Api.get('/altacm/s/user-profile/$userId/moderated-communities');
  }

}