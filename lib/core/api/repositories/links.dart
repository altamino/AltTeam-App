import '../network/api.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:typed_data';
import 'package:path/path.dart' as p; // Для автоматического определения расширения файла

class LinksRepository {


  Future<Map<String, dynamic>> get_from_id(String objectId, int objectType, ndcId) async {
    return await Api.post('/g/s-x${ndcId}/link-resolution', body:{
			"objectId": objectId,
			"targetCode": 1,
			"objectType": objectType,
		}
);
  }

  Future<Map<String, dynamic>> get_from_link(String link) async {
    return await Api.get('/g/s/link-resolution?q=${link}"');
  }

  /// Загрузить медиафайл на сервер.
  /// [file] - объект файла (XFile или File).
  /// [mimeType] - вручную указанный тип (например, 'image/jpeg'). Если null, тип определится по расширению.
  Future<Map<String, dynamic>> uploadMedia({
    required XFile file,
    String? mimeType,
  }) async {
    // 1. Читаем контент файла в байты (работает асинхронно и безопасно на всех платформах)
    final Uint8List fileBytes = await file.readAsBytes();

    // 2. Если MIME-тип не передан, определяем его по расширению файла
    String resolvedMimeType = mimeType ?? _guessMimeType(file.name);

    // 3. Делаем POST-запрос с байтами в теле и нужным заголовком Content-Type
    // Примечание: Убедитесь, что ваш класс Api.post умеет принимать Uint8List как data/body.
    final response = await Api.post(
      '/g/s/media/upload',
      body: fileBytes,
      headers: {
        'Content-Type': resolvedMimeType,
      },
    );

    return response;
  }

  /// Простая функция определения MIME-типа по расширению
  String _guessMimeType(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream'; // Дефолтный бинарный тип
    }
  }




}
