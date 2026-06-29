import '../network/api.dart';

class AltACMRepository {
  Future<void> unpromote_user(String userId, int ndcId) async {
    await Api.delete('/altacm/s/community/x${ndcId}/user/${userId}/promote');
  }
  Future<void> promote_user(String userId, int ndcId, role) async {
    await Api.post('/altacm/s/community/x${ndcId}/user/${userId}/promote', body: {
      "role": role
    });
  }

  Future<void> create_community(String name, aminoId, agentGlobalLink, lang) async {
    await Api.post('/altacm/s/community/create', body: {
			"name": name,
			"aminoId": aminoId,
			"agentGlobalLink": agentGlobalLink,
			"lang": lang
		});
  }  

  Future<void> delete_community(int ndcId) async {
    await Api.delete('/altacm/s/community/x${ndcId}/destroy');
  }

}