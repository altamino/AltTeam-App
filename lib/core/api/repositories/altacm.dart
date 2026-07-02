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
Future<Map<String, dynamic>> editCommunity(
  int ndcId, {
  String? name,
  String? aminoId,
  String? tagline,
  String? description,
  String? guidelines,
  String? icon,
  String? themeUrl,
  String? themeColor,
  int? themeRevision,
  String? coverUrl,
  String? welcomeMessage,
  bool? welcomeMessageEnabled,
  String? language,
  int? joinType,
  bool? hidden,
}) async {
  final body = <String, dynamic>{};

  if (name != null) body['name'] = name;
  if (aminoId != null) body['aminoId'] = aminoId;
  if (tagline != null) body['tagline'] = tagline;
  if (description != null) body['description'] = description;
  if (guidelines != null) body['guidelines'] = guidelines;
  if (icon != null) body['icon'] = icon;
  if (themeUrl != null) body['themeUrl'] = themeUrl;
  if (themeColor != null) body['themeColor'] = themeColor;
  if (themeRevision != null) body['themeRevision'] = themeRevision;
  if (coverUrl != null) body['coverUrl'] = coverUrl;

  if (language != null) body['lang'] = language;

  final configuration = <String, dynamic>{};
  if (welcomeMessage != null) configuration['welcomeMessage'] = welcomeMessage;
  if (welcomeMessageEnabled != null) configuration['welcomeMessageEnabled'] = welcomeMessageEnabled;
  if (joinType != null) configuration['joinType'] = joinType;
  if (hidden != null) configuration['hidden'] = hidden;
  if (configuration.isNotEmpty) body['configuration'] = configuration;

  return await Api.post('/altacm/s/community/x$ndcId/edit', body: body);
}




  Future<Map<String, dynamic>> getUserManagedCommunities(String userId) async {
    return await Api.get('/altacm/s/user-profile/$userId/moderated-communities');
  }

}