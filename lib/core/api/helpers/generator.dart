import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../constants.dart';


final Uint8List _sigKey = _hexToBytes(SigKey);
final Uint8List _deviceKey = _hexToBytes(DeviceKey);


// ─── Helpers ────────────────────────────────────────────────────────────────

Uint8List _hexToBytes(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (int i = 0; i < hex.length; i += 2) {
    result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
  }
  return result;
}

Uint8List _hmacSha1(Uint8List key, Uint8List data) {
  final hmac = Hmac(sha1, key);
  return Uint8List.fromList(hmac.convert(data).bytes);
}

// ─── Generator ──────────────────────────────────────────────────────────────

class Generator {
  static final Random _random = Random.secure();

  static String strUuid4() {
    final bytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      bytes[i] = _random.nextInt(256);
    }
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static int reqTime() =>
      DateTime.now().millisecondsSinceEpoch;

  static int clientRefId() =>
      (DateTime.now().millisecondsSinceEpoch / 10000 % 1000000000).toInt();

  static String genDeviceId([Uint8List? data]) {
    final seed = data ?? _randomBytes(20);
    final identifier = Uint8List(Prefix.length + seed.length)
      ..setAll(0, Prefix)
      ..setAll(Prefix.length, seed);
    final mac = _hmacSha1(_deviceKey, identifier);
    return (identifier.map((b) => b.toRadixString(16).padLeft(2, '0')).join() +
            mac.map((b) => b.toRadixString(16).padLeft(2, '0')).join())
        .toUpperCase();
  }

  static String updateDeviceId(String device) {
    final data = _hexToBytes(device.substring(2, 42));
    return genDeviceId(data);
  }


  static String signature(dynamic data) {
    late Uint8List bytes;
    if (data is String) {
      bytes = Uint8List.fromList(utf8.encode(data));
    } else if (data is Map || data is List) {
      bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
    } else if (data is Uint8List) {
      bytes = data;
    } else {
      throw ArgumentError('Unsupported data type: ${data.runtimeType}');
    }

    final mac = _hmacSha1(_sigKey, bytes);
    final result = Uint8List(Prefix.length + mac.length)
      ..setAll(0, Prefix)
      ..setAll(Prefix.length, mac);
    return base64Encode(result);
  }

  static Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List.generate(length, (_) => _random.nextInt(256)),
    );
  }
}