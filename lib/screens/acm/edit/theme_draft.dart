import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/api/repositories/links.dart';
import '../../../../core/api/repositories/theme_editor.dart';
import 'safe_notify.dart';

class ThemeUpload {
  const ThemeUpload({this.url, this.revision, this.color});
  final String? url;
  final int? revision;
  final String? color;
}

class ThemeDraft extends ChangeNotifier with SafeNotify {
  bool enabled = false;
  bool compress = true;

  String? packUrl;
  int serverRevision = 0;
  String colorHex = '';

  ThemeEditor? editor;
  bool loading = false;
  String? loadError;

  XFile? newBackground;
  XFile? newTitlebarBg;
  XFile? newTitlebar;
  bool removeBackground = false;
  bool removeTitlebarBg = false;
  bool removeTitlebar = false;

  int get currentRevision => editor?.revision ?? serverRevision;

  void init({String? packUrl, int revision = 0, String colorHex = ''}) {
    this.packUrl = packUrl;
    serverRevision = revision;
    this.colorHex = colorHex;
    notifyListeners();
  }

  void setEnabled(bool v) {
    enabled = v;
    notifyListeners();
    if (v) loadExisting();
  }

  void setCompress(bool v) {
    compress = v;
    notifyListeners();
  }

  void setColor(String hex) {
    colorHex = hex;
    notifyListeners();
  }

  void setBackground(XFile f) {
    newBackground = f;
    removeBackground = false;
    notifyListeners();
  }

  void clearBackground() {
    newBackground = null;
    removeBackground = true;
    notifyListeners();
  }

  void setTitlebarBg(XFile f) {
    newTitlebarBg = f;
    removeTitlebarBg = false;
    notifyListeners();
  }

  void clearTitlebarBg() {
    newTitlebarBg = null;
    removeTitlebarBg = true;
    notifyListeners();
  }

  void setTitlebar(XFile f) {
    newTitlebar = f;
    removeTitlebar = false;
    notifyListeners();
  }

  void clearTitlebar() {
    newTitlebar = null;
    removeTitlebar = true;
    notifyListeners();
  }

  Future<void> loadExisting() async {
    if (editor != null || loading) return;
    final url = packUrl;
    if (url == null || url.isEmpty) {
      editor = ThemeEditor.newTheme();
      notifyListeners();
      return;
    }

    loading = true;
    loadError = null;
    notifyListeners();

    try {
      final bytes = await _downloadBytes(url);
      final e = ThemeEditor.fromBytes(bytes);
      if (serverRevision > e.revision) e.revision = serverRevision;
      editor = e;
    } catch (err) {
      final e = ThemeEditor.newTheme();
      if (serverRevision > 0) e.revision = serverRevision;
      editor = e;
      loadError = err.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Uint8List> _downloadBytes(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception(
            'Theme pack download failed: HTTP ${response.statusCode}');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      client.close();
    }
  }

  Future<ThemeUpload> prepareUpload({
    required LinksRepository links,
    required int ndcId,
  }) async {
    if (!enabled) return const ThemeUpload();

    final color = colorHex.isNotEmpty ? colorHex : null;
    final hasNewImages =
        newBackground != null || newTitlebarBg != null || newTitlebar != null;
    final hasRemovals = removeBackground || removeTitlebarBg || removeTitlebar;

    if (!(hasNewImages || hasRemovals || color != null)) {
      return ThemeUpload(color: color);
    }

    if (editor == null) await loadExisting();
    final ed = editor ?? ThemeEditor.newTheme();

    if (removeBackground && newBackground == null) {
      ed.removeImage('background');
    }
    if (removeTitlebarBg && newTitlebarBg == null) {
      ed.removeImage('titlebarbg');
    }
    if (removeTitlebar && newTitlebar == null) {
      ed.removeImage('titlebar');
    }

    if (newBackground != null) {
      ed.injectImage(
        forWhat: 'background',
        newImageData: await newBackground!.readAsBytes(),
        compress: compress,
      );
    }
    if (newTitlebarBg != null) {
      ed.injectImage(
        forWhat: 'titlebarbg',
        newImageData: await newTitlebarBg!.readAsBytes(),
        compress: compress,
      );
    }
    if (newTitlebar != null) {
      ed.injectImage(
        forWhat: 'titlebar',
        newImageData: await newTitlebar!.readAsBytes(),
        compress: compress,
      );
    }
    if (color != null) ed.setThemeColor(color);

    ed.incrementRevision();
    final zipBytes = ed.rebuild();

    final up = await links.uploadThemeArchive(zipBytes: zipBytes, ndcId: ndcId);
    final String? url = up['mediaValue'];
    return ThemeUpload(url: url, revision: ed.revision, color: color);
  }
}