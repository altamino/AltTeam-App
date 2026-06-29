import '../network/api.dart';

class BlogsRepository {
  Future<Map<String, dynamic>> getAnnouncements({
    String? language,
    int? start,
    int? size,
    DateTime? stopTime,
  }) async {
    final queryParams = <String, String>{
      'language': language ?? 'en',
      if (start != null) 'start': start.toString(),
      if (size != null) 'size': size.toString(),
      if (stopTime != null) 'stoptime': stopTime.toUtc().toIso8601String(),
    };

    final uri = Uri(
      path: '/g/s/announcement',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    return await Api.get(uri.toString());
  }


  Future<Map<String, dynamic>> createBlog({
    int? ndcId,
    required String title,
    required String content,
    String language = 'en',
    String? mediaUrl,
    String? mediaFileName,
    String? backgroundColor,
    String? bgMediaUrl,
    String? bgMediaFileName,
  }) async {
    
    final path = '/x${ndcId ?? 0}/s/blog';


    List<dynamic>? formattedMediaList;
    if (mediaUrl != null) {
      formattedMediaList = [
        [
          100,
          mediaUrl,
          null,
          null,
          null,
          if (mediaFileName != null) {'fileName': mediaFileName} else null,
        ]
      ];
    }

  
    List<dynamic>? formattedBgMediaList;
    if (bgMediaUrl != null) {
      formattedBgMediaList = [
        [
          100,
          bgMediaUrl,
          null,
          null,
          null,
          if (bgMediaFileName != null) {'fileName': bgMediaFileName} else null,
        ]
      ];
    }

    final Map<String, dynamic> requestBody = {
      'title': title,
      'content': content,
      'type': 0,
      'contentLanguage': language,
      'address': null,
      'latitude': 0,
      'longitude': 0,
      'promotedFrom': null,
      'eventSource': 'GlobalComposeMenu',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'mediaList': formattedMediaList,
      'extensions': {
        'fansOnly': false,
        'style': {
          'backgroundColor': backgroundColor,
          'backgroundMediaList': formattedBgMediaList,
        }
      },
    };


    return await Api.post(path, body: requestBody); 

  }


Future<Map<String, dynamic>> editBlog({
    required String blogId,
    int? ndcId,
    String? title,
    String? content,
    List<dynamic>? mediaList,
    String? backgroundColor,
    String? bgMediaUrl,
    String? bgMediaFileName,
    int? commentAllowance,
  }) async {

    final isGlobal = ndcId == null || ndcId == 0;
    final path = isGlobal ? '/g/s/blog/$blogId' : '/x$ndcId/s/blog/$blogId';


    final Map<String, dynamic> requestBody = {};

    if (title != null) requestBody['title'] = title;
    if (content != null) requestBody['content'] = content;
    if (mediaList != null) requestBody['mediaList'] = mediaList;


    final Map<String, dynamic> extensions = {};
    final Map<String, dynamic> style = {};

    if (backgroundColor != null) style['backgroundColor'] = backgroundColor;
    if (bgMediaUrl != null) {
      style['backgroundMediaList'] = [
        [
          100,
          bgMediaUrl,
          null,
          null,
          null,
          if (bgMediaFileName != null) {'fileName': bgMediaFileName} else null,
        ]
      ];
    }

    if (style.isNotEmpty) {
      extensions['style'] = style;
    }

    if (commentAllowance != null) {

      extensions['privilegeOfCommentOnPost'] = commentAllowance;
    }

    if (extensions.isNotEmpty) {
      requestBody['extensions'] = extensions;
    }


    return await Api.post(path, body: requestBody);
  }


  Future<Map<String, dynamic>> deleteBlog({
    required String blogId,
    int? ndcId,
  }) async {
    final isGlobal = ndcId == null || ndcId == 0;
    final path = isGlobal ? '/g/s/blog/$blogId' : '/x$ndcId/s/blog/$blogId';

    return await Api.delete(path);
  }


}