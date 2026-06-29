import '../network/api.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

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

  Future<Map<String, dynamic>> uploadMedia({
    required XFile file,
    String? mimeType,
  }) async {

    final Uint8List fileBytes = await file.readAsBytes();

    String resolvedMimeType = mimeType ?? _guessMimeType(file.name);

    final response = await Api.post(
      '/g/s/media/upload',
      body: fileBytes,
      headers: {
        'Content-Type': resolvedMimeType,
      },
    );

    return response;
  }

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
        return 'application/octet-stream';
    }
  }




}
