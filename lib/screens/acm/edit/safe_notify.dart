import 'package:flutter/foundation.dart';

typedef Notify = void Function(String message, {bool error});


mixin SafeNotify on ChangeNotifier {
  bool _disposed = false;
  bool get disposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}