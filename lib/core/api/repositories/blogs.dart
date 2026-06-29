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

  /// Создать новый блог/пост
  /// [ndcId] - ID сообщества (если 0 или null, подставится глобальный поиск/создание)
  /// [title] - Заголовок поста
  /// [content] - Текст поста
  /// [language] - Язык контента (по умолчанию 'en')
  /// [mediaUrl] - Ссылка на прикрепленное изображение (опционально)
  /// [mediaFileName] - Имя файла прикрепленного изображения (опционально)
  /// [backgroundColor] - HEX-цвет фона в формате '#000000' (опционально)
  /// [bgMediaUrl] - Ссылка на фоновое изображение поста (опционально)
  /// [bgMediaFileName] - Имя фонового файла (опционально)
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
    
    // Безопасный сбор пути с учетом ndcId
    final path = '/x${ndcId ?? 0}/s/blog';

    // Формируем структуру mediaList, если передана ссылка
    List<dynamic>? formattedMediaList;
    if (mediaUrl != null) {
      formattedMediaList = [
        [
          100, // Константный маркер типа медиа у Amino
          mediaUrl,
          null,
          null,
          null,
          if (mediaFileName != null) {'fileName': mediaFileName} else null,
        ]
      ];
    }

    // Формируем структуру backgroundMediaList
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

    // Собираем всё тело POST-запроса (payload)
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
      'mediaList': formattedMediaList, // Подставит null или массив
      'extensions': {
        'fansOnly': false,
        'style': {
          'backgroundColor': backgroundColor, // Подставит null или строку формата '#000000'
          'backgroundMediaList': formattedBgMediaList,
        }
      },
    };

    // Отправляем POST запрос через ваш Api класс
    return await Api.post(path, body: requestBody); 
    // Примечание: Если ваш Api.post принимает body вторым позиционным аргументом, 
    // измените на: await Api.post(path, requestBody);
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
    // Формируем путь: если ndcId нет или он 0, шлем на глобальный /g/s/...
    final isGlobal = ndcId == null || ndcId == 0;
    final path = isGlobal ? '/g/s/blog/$blogId' : '/x$ndcId/s/blog/$blogId';

    // Собираем только измененные данные (payload)
    final Map<String, dynamic> requestBody = {};

    if (title != null) requestBody['title'] = title;
    if (content != null) requestBody['content'] = content;
    if (mediaList != null) requestBody['mediaList'] = mediaList;

    // Сбор вложенного объекта extensions и style, если они переданы
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
      // Сервер бэкенда мапит 'privilegeOfCommentOnPost' в 'commentAllowance'
      extensions['privilegeOfCommentOnPost'] = commentAllowance;
    }

    if (extensions.isNotEmpty) {
      requestBody['extensions'] = extensions;
    }

    // Отправляем POST-запрос на редактирование
    return await Api.post(path, body: requestBody);
  }

  /// Удалить блог/пост
  /// [blogId] - ID удаляемого поста
  /// [ndcId] - ID сообщества (если 0 или null, запрос пойдет в глобальный /g/s/blog)
  Future<Map<String, dynamic>> deleteBlog({
    required String blogId,
    int? ndcId,
  }) async {
    final isGlobal = ndcId == null || ndcId == 0;
    final path = isGlobal ? '/g/s/blog/$blogId' : '/x$ndcId/s/blog/$blogId';

    // Вызываем метод DELETE через Api класс
    return await Api.delete(path);
  }


}