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


  Future<void> banUser(String userId, int ndcId) async {
    //await Api.post('/altacm/s/community/x${ndcId}/user/${userId}/ban');
  }
  Future<void> unbanUser(String userId, int ndcId) async {
    //await Api.post('/altacm/s/community/x${ndcId}/user/${userId}/unban');
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
Future<Map<String, dynamic>> editCommunity(
    int ndcId, {
    String? name,
    String? aminoId,
    String? tagline,
    String? description,
    List<dynamic>? descriptionMediaList,
    String? guidelines,
    List<dynamic>? guidelineMediaList,
    String? icon,
    String? coverUrl,
    String? themeUrl,
    String? themeColor,
    int? themeRevision,
    String? welcomeMessage,
    bool? welcomeMessageEnabled,
    int? joinType,
    bool? hidden,
    String? language,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (aminoId != null) 'aminoId': aminoId,
      if (tagline != null) 'tagline': tagline,
      if (description != null) 'description': description,
      if (descriptionMediaList != null) 'mediaList': descriptionMediaList,
      if (guidelines != null) 'guideline': guidelines,
      if (guidelineMediaList != null) 'guidelineMediaList': guidelineMediaList,
      if (icon != null) 'icon': icon,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (themeUrl != null) 'themeUrl': themeUrl,
      if (themeColor != null) 'themeColor': themeColor,
      if (themeRevision != null) 'themeRevision': themeRevision,
      if (language != null) 'lang': language,
      'configuration': {
        if (welcomeMessage != null) 'welcomeMessage': welcomeMessage,
        if (welcomeMessageEnabled != null) 'welcomeMessageEnabled': welcomeMessageEnabled,
        if (joinType != null) 'joinType': joinType,
        if (hidden != null) 'hidden': hidden,
      },
    };
    return await Api.post('/altacm/s/community/x$ndcId/edit', body: body);
  }


  Future<Map<String, dynamic>> getUserManagedCommunities(String userId) async {
    return await Api.get('/altacm/s/user-profile/$userId/moderated-communities');
  }

}