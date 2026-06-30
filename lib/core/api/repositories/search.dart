import '../network/api.dart';

class SearchRepository {
Future<Map<String, dynamic>> searchUser({
  int? ndcId,
  String? lang,
  String? q,
  int? size,
  String? pageToken,
}) async {

  final queryParams = <String, String>{
    if (q != null && q.isNotEmpty) 'q': q,
    if (size != null) 'size': size.toString(),
    if (pageToken != null && pageToken.isNotEmpty) 'pageToken': pageToken,
    if (lang != null && lang.isNotEmpty) 'language': lang,
  };

  final uri = Uri(
    path: '/x${ndcId ?? 0}/s/user-profile/search',
    queryParameters: queryParams.isEmpty ? null : queryParams,
  );

  return await Api.get(uri.toString());
}



Future<Map<String, dynamic>> searchCommunity({
  String? lang,
  String? q,
  int? start,
  int? size,
  String? pageToken,
}) async {

  final queryParams = <String, String>{
    if (q != null && q.isNotEmpty) 'q': q,
    if (start != null) 'start': start.toString(),
    if (size != null) 'size': size.toString(),
    if (pageToken != null && pageToken.isNotEmpty) 'pageToken': pageToken,
    if (lang != null && lang.isNotEmpty) 'language': lang,
  };

  final uri = Uri(
    path: '/g/s/community/search',
    queryParameters: queryParams.isEmpty ? null : queryParams,
  );

  return await Api.get(uri.toString());
}


Future<Map<String, dynamic>> getAvailableLanguages() async {
  return await Api.get("/g/s/community-collection/supported-languages");
}


}