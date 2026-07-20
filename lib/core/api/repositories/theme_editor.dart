import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

class ThemeFile {
  String path;
  Uint8List data;
  int width;
  int height;
  ThemeFile({required this.path, required this.data, this.width = 0, this.height = 0});
}

class ThemeEditor {
  ThemeFile? info;

  List<ThemeFile> background = [];
  List<ThemeFile> titlebar = [];
  List<ThemeFile> icon = [];
  List<ThemeFile> titlebarBackground = [];

  Map<String, dynamic> themeJson = {};

  static const Map<String, String> _folders = {
    'logo': 'images/logo',
    'titlebar': 'images/titlebar',
    'background': 'images/background',
    'titlebarbg': 'images/titlebarBackground',
  };

  static const Map<String, String> _filePrefixes = {
    'logo': 'logo',
    'titlebar': 'titlebar',
    'background': 'background',
    'titlebarbg': 'titlebarBackground',
  };

  static const Map<String, String> _jsonKeys = {
    'logo': 'logo',
    'titlebar': 'titlebar-image',
    'background': 'background-image',
    'titlebarbg': 'titlebar-background-image',
  };

  static const int _bgWidth2x = 750;
  static const int _bgHeight2x = 1334;
  static const int _titlebarMaxW2x = 640;
  static const int _titlebarMaxH2x = 256;

  ThemeEditor._();

  static ThemeEditor fromBytes(Uint8List archiveBytes) {
    final editor = ThemeEditor._();
    final archive = ZipDecoder().decodeBytes(archiveBytes);

    for (final file in archive) {
      if (!file.isFile) continue;

      final filename = file.name;
      final fileData = file.content as Uint8List;

      if (filename.endsWith('theme_info.json')) {
        editor.info = ThemeFile(path: filename, data: fileData);
        try {
          editor.themeJson = jsonDecode(utf8.decode(fileData));
        } catch (_) {
          editor.themeJson = {};
        }
      } else if (filename.startsWith('images/background/')) {
        editor.background.add(ThemeFile(path: filename, data: fileData));
      } else if (filename.startsWith('images/titlebarBackground/')) {
        editor.titlebarBackground.add(ThemeFile(path: filename, data: fileData));
      } else if (filename.startsWith('images/titlebar/')) {
        editor.titlebar.add(ThemeFile(path: filename, data: fileData));
      } else if (filename.startsWith('images/logo/')) {
        editor.icon.add(ThemeFile(path: filename, data: fileData));
      }
    }

    int bySize(ThemeFile a, ThemeFile b) => b.data.length.compareTo(a.data.length);
    editor.background.sort(bySize);
    editor.titlebarBackground.sort(bySize);
    editor.titlebar.sort(bySize);
    editor.icon.sort(bySize);

    editor.themeJson["author"] ??= "AltTeam";
    editor.themeJson["format-version"] ??= "1.0";
    editor.themeJson["revision"] = editor.revision;
    if (editor.themeJson["id"] == "oled-black-theme" || editor.themeJson["id"] == null) {
      editor.themeJson["id"] = const Uuid().v4();
    }

    return editor;
  }

  static ThemeEditor newTheme({String? themeId}) {
    final editor = ThemeEditor._();
    editor.themeJson = {
      "id": themeId ?? const Uuid().v4(),
      "format-version": "1.0",
      "author": "AltTeam",
      "revision": 0,
    };
    editor.info = ThemeFile(path: 'theme_info.json', data: Uint8List(0));
    return editor;
  }

  int get revision {
    final r = themeJson["revision"];
    if (r is int) return r;
    if (r is num) return r.toInt();
    if (r is String) return int.tryParse(r) ?? 0;
    return 0;
  }

  set revision(int value) => themeJson["revision"] = value;

  void incrementRevision() {
    themeJson["revision"] = revision + 1;
  }

  void setThemeColor(String hexColor) {
    final hex = RegExp(r'^#([0-9a-fA-F]{6})$');
    if (!hex.hasMatch(hexColor)) {
      throw Exception("Invalid theme color: $hexColor (expected #RRGGBB)");
    }
    themeJson["theme-color"] = hexColor;
  }

  Uint8List? get backgroundBytes => background.isEmpty ? null : background.first.data;
  Uint8List? get titlebarBytes => titlebar.isEmpty ? null : titlebar.first.data;
  Uint8List? get logoBytes => icon.isEmpty ? null : icon.first.data;
  Uint8List? get titlebarBackgroundBytes =>
      titlebarBackground.isEmpty ? null : titlebarBackground.first.data;

  String _canonicalKey(String forWhat) {
    switch (forWhat.toLowerCase()) {
      case "icon":
      case "logo":
        return "logo";
      case "titlebar":
      case "tb":
      case "tbar":
        return "titlebar";
      case "background":
      case "bg":
        return "background";
      case "titlebarbg":
      case "titlebarbackground":
      case "tbarbg":
      case "tbbg":
      case "sidebarbg":
        return "titlebarbg";
      default:
        throw Exception("Invalid forWhat parameter: $forWhat");
    }
  }

  List<ThemeFile> _slotList(String canonical) {
    switch (canonical) {
      case "logo":
        return icon;
      case "titlebar":
        return titlebar;
      case "background":
        return background;
      case "titlebarbg":
        return titlebarBackground;
      default:
        throw Exception("Unknown slot: $canonical");
    }
  }

  img.Image _coverCrop(img.Image src, int tw, int th) {
    final scale = math.max(tw / src.width, th / src.height);
    final rw = math.max(tw, (src.width * scale).ceil());
    final rh = math.max(th, (src.height * scale).ceil());
    var out = img.copyResize(
      src,
      width: rw,
      height: rh,
      interpolation: img.Interpolation.average,
    );
    final x = ((rw - tw) / 2).round();
    final y = ((rh - th) / 2).round();
    out = img.copyCrop(out, x: x, y: y, width: tw, height: th);
    return out;
  }

  img.Image _fitInside(img.Image src, int maxW, int maxH) {
    if (src.width <= maxW && src.height <= maxH) return src;
    final scale = math.min(maxW / src.width, maxH / src.height);
    return img.copyResize(
      src,
      width: math.max(1, (src.width * scale).round()),
      height: math.max(1, (src.height * scale).round()),
      interpolation: img.Interpolation.average,
    );
  }

  bool _isJpegBytes(Uint8List bytes) {
    return bytes.length > 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
  }

  bool _isPngBytes(Uint8List bytes) {
    return bytes.length > 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
  }

  void _writeSlot(String canonical, List<ThemeFile> files) {
    themeJson[_jsonKeys[canonical]!] = [
      for (final f in files)
        {"path": f.path, "width": f.width, "height": f.height, "x": 0, "y": 0}
    ];
  }

  void injectImage({
    required String forWhat,
    required Uint8List newImageData,
    bool compress = true,
  }) {
    final canonical = _canonicalKey(forWhat);

    var decoded = img.decodeImage(newImageData);
    if (decoded == null) throw Exception("Invalid image data");

    decoded = img.bakeOrientation(decoded);

    if (canonical == "logo" && decoded.width != decoded.height) {
      throw Exception("Logo should be square!");
    }

    final folder = _folders[canonical]!;
    final prefix = _filePrefixes[canonical]!;
    final files = _slotList(canonical);

    if (!compress || canonical == "logo") {
      Uint8List outBytes;
      String ext;

      if (_isJpegBytes(newImageData)) {
        outBytes = newImageData;
        ext = '.jpeg';
      } else if (_isPngBytes(newImageData)) {
        outBytes = newImageData;
        ext = '.png';
      } else {
        outBytes = Uint8List.fromList(img.encodePng(decoded));
        ext = '.png';
      }

      final w = decoded.width;
      final h = decoded.height;
      final path = "$folder/${prefix}_${w}x$h$ext";

      files
        ..clear()
        ..add(ThemeFile(path: path, data: outBytes, width: w, height: h));

      _writeSlot(canonical, files);
      return;
    }

    final bool isBackgroundSlot = canonical == "background" || canonical == "titlebarbg";
    img.Image processed;
    bool asJpeg;

    if (isBackgroundSlot) {
      processed = _coverCrop(decoded, _bgWidth2x, _bgHeight2x);
      asJpeg = true;
    } else if (canonical == "titlebar") {
      processed = _fitInside(decoded, _titlebarMaxW2x, _titlebarMaxH2x);
      asJpeg = false;
    } else {
      processed = _fitInside(decoded, 256, 256);
      asJpeg = false;
    }

    final w2 = processed.width;
    final h2 = processed.height;

    final bytes2x = Uint8List.fromList(
      asJpeg
          ? img.encodeJpg(processed, quality: 70)
          : img.encodePng(processed, level: 9),
    );

    final w1 = math.max(1, (w2 / 2).round());
    final h1 = math.max(1, (h2 / 2).round());
    final half = img.copyResize(
      processed,
      width: w1,
      height: h1,
      interpolation: img.Interpolation.average,
    );

    final bytes1x = Uint8List.fromList(
      asJpeg
          ? img.encodeJpg(half, quality: 70)
          : img.encodePng(half, level: 9),
    );

    final ext = asJpeg ? '.jpeg' : '.png';
    final path2x = "$folder/${prefix}_${w2}x$h2$ext";
    final path1x = "$folder/${prefix}_${w1}x$h1$ext";

    files
      ..clear()
      ..add(ThemeFile(path: path2x, data: bytes2x, width: w2, height: h2));

    if (path1x != path2x) {
      files.add(ThemeFile(path: path1x, data: bytes1x, width: w1, height: h1));
    }

    _writeSlot(canonical, files);
  }

  void removeImage(String forWhat) {
    final canonical = _canonicalKey(forWhat);
    _slotList(canonical).clear();
    themeJson.remove(_jsonKeys[canonical]);
  }

  Uint8List rebuild() {
    final encoder = ZipEncoder();
    final archive = Archive();

    themeJson["revision"] = revision;

    final jsonStr = jsonEncode(themeJson);
    info ??= ThemeFile(path: 'theme_info.json', data: Uint8List(0));
    info!.data = Uint8List.fromList(utf8.encode(jsonStr));

    final filesToPack = <ThemeFile>[
      info!,
      ...background,
      ...titlebar,
      ...icon,
      ...titlebarBackground,
    ];

    for (final file in filesToPack) {
      if (file.data.isNotEmpty) {
        archive.addFile(ArchiveFile(file.path, file.data.length, file.data));
      }
    }

    final zipBytes = encoder.encode(archive);
    return Uint8List.fromList(zipBytes!);
  }
}