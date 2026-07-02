import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

class ThemeFile {
  String path;
  Uint8List data;
  ThemeFile({required this.path, required this.data});
}

class ThemeEditor {
  ThemeFile? info;
  ThemeFile? background;
  ThemeFile? titlebar;
  ThemeFile? icon;
  ThemeFile? titlebarBackground;

  Map<String, dynamic> themeJson = {};

  // Папки внутри архива для каждого компонента темы.
  static const Map<String, String> _folders = {
    'logo': 'images/logo',
    'titlebar': 'images/titlebar',
    'background': 'images/background',
    'titlebarbg': 'images/titlebarBackground',
  };

  ThemeEditor._();

  /// Загрузка существующего .ndthemepack (как раньше — для случаев,
  /// когда тема уже есть и нужно её отредактировать).
  static ThemeEditor fromBytes(Uint8List archiveBytes) {
    final editor = ThemeEditor._();
    final archive = ZipDecoder().decodeBytes(archiveBytes);

    for (final file in archive) {
      if (!file.isFile) continue;

      final filename = file.name;
      final fileData = file.content as Uint8List;

      if (filename.endsWith('theme_info.json')) {
        editor.info = ThemeFile(path: filename, data: fileData);
        editor.themeJson = jsonDecode(utf8.decode(fileData));
      } else if (filename.startsWith('images/background/')) {
        editor.background = ThemeFile(path: filename, data: fileData);
      } else if (filename.startsWith('images/titlebarBackground/')) {
        editor.titlebarBackground = ThemeFile(path: filename, data: fileData);
      } else if (filename.startsWith('images/titlebar/')) {
        editor.titlebar = ThemeFile(path: filename, data: fileData);
      } else if (filename.startsWith('images/logo/')) {
        editor.icon = ThemeFile(path: filename, data: fileData);
      }
    }

    editor.themeJson["author"] = "AltTeam";
    if (editor.themeJson["id"] == "oled-black-theme" || editor.themeJson["id"] == null) {
      editor.themeJson["id"] = const Uuid().v4();
    }

    return editor;
  }

  /// Создание НОВОЙ темы "с нуля" — без исходного zip-файла.
  /// Пользователь просто выбирает картинки, а мы собираем валидный
  /// .ndthemepack прямо на клиенте.
  static ThemeEditor newTheme({String? themeId}) {
    final editor = ThemeEditor._();
    editor.themeJson = {
      "id": themeId ?? const Uuid().v4(),
      "author": "AltTeam",
      "revision": 0,
    };
    // info-файл будет пересобран в rebuild(), тут просто резервируем путь.
    editor.info = ThemeFile(path: 'theme_info.json', data: Uint8List(0));
    return editor;
  }

  int get revision => themeJson["revision"] ?? 0;

  void incrementRevision() {
    final currentRevision = themeJson["revision"] ?? 0;
    themeJson["revision"] = currentRevision + 1;
  }

  String _canonicalKey(String forWhat) {
    switch (forWhat.toLowerCase()) {
      case "icon":
      case "logo":
        return "logo";
      case "titlebar":
      case "tb":
      case "tbar":
      case "titlebarbackground": // алиас как в исходном коде — считаем titlebar-картинкой
        return "titlebar";
      case "background":
      case "bg":
      case "leftpanel":
        return "background";
      case "titlebarbg":
      case "tbarbg":
      case "tbbg":
        return "titlebarbg";
      default:
        throw Exception("Invalid forWhat parameter: $forWhat");
    }
  }

  String _detectExt(Uint8List data) {
    if (data.length > 3 && data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) {
      return '.jpg';
    }
    if (data.length > 8 &&
        data[0] == 0x89 &&
        data[1] == 0x50 &&
        data[2] == 0x4E &&
        data[3] == 0x47) {
      return '.png';
    }
    return '.png';
  }

  /// Внедрение картинки. Работает как для уже загруженной темы (fromBytes),
  /// так и для темы, собираемой с нуля (newTheme) — во втором случае слот
  /// компонента создаётся впервые, а путь берётся из фиксированной папки.
  void injectImage({
    required String forWhat,
    required Uint8List newImageData,
  }) {
    final canonical = _canonicalKey(forWhat);

    final decodedImage = img.decodeImage(newImageData);
    if (decodedImage == null) throw Exception("Invalid image data");

    final width = decodedImage.width;
    final height = decodedImage.height;

    if (canonical == "logo" && width != height) {
      throw Exception("Logo should be square!");
    }

    final ext = _detectExt(newImageData);
    // Если компонент уже существовал (fromBytes) — сохраняем его папку,
    // иначе берём папку по умолчанию (создание с нуля).
    final existingPath = switch (canonical) {
      "logo" => icon?.path,
      "titlebar" => titlebar?.path,
      "background" => background?.path,
      "titlebarbg" => titlebarBackground?.path,
      _ => null,
    };
    final folder = existingPath != null
        ? existingPath.substring(0, existingPath.lastIndexOf('/'))
        : _folders[canonical]!;

    final newFileName = "file_${DateTime.now().millisecondsSinceEpoch}$ext";
    final newPath = "$folder/$newFileName";
    final newFile = ThemeFile(path: newPath, data: newImageData);

    switch (canonical) {
      case "logo":
        icon = newFile;
        break;
      case "titlebar":
        titlebar = newFile;
        break;
      case "background":
        background = newFile;
        break;
      case "titlebarbg":
        titlebarBackground = newFile;
        break;
    }

    final jsonKey = switch (canonical) {
      "logo" => "logo",
      "titlebar" => "titlebar-background-image",
      "background" => "background-image",
      _ => null, // titlebarbg не мапится напрямую в theme_info.json
    };

    if (jsonKey != null) {
      themeJson[jsonKey] = [
        {"path": newPath, "width": width, "height": height}
      ];
    }
  }

  /// Пересборка всех файлов обратно в zip-архив.
  /// Пустые/неустановленные компоненты в архив не попадают.
  Uint8List rebuild() {
    final encoder = ZipEncoder();
    final archive = Archive();

    final jsonStr = jsonEncode(themeJson);
    info ??= ThemeFile(path: 'theme_info.json', data: Uint8List(0));
    info!.data = Uint8List.fromList(utf8.encode(jsonStr));

    final filesToPack = [info, background, titlebar, icon, titlebarBackground];

    for (final file in filesToPack) {
      if (file != null && file.data.isNotEmpty) {
        archive.addFile(ArchiveFile(file.path, file.data.length, file.data));
      }
    }

    final zipBytes = encoder.encode(archive);
    return Uint8List.fromList(zipBytes!);
  }
}