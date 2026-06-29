import 'dart:typed_data';

// Constants
const String apiUrl = "https://dev-service.altamino.top/api/v1";
const String UserAgent = 'Apple iPhone16,1 iOS v15.0 Main/3.22.0';
const String AppVersion = '1.0.2';
const String tgBotUrl = 'https://t.me/alttrinity_bot';
const String baseAltAminoUrl = 'https://altamino.top';

final Uint8List Prefix = Uint8List.fromList([0x19]);
final String SigKey = "DFA5ED192DDA6E88A12FE12130DC6206B1251E44";
final String DeviceKey = "E7309ECC0953C6FA60005B2765F99DBBC965C8E9";
final String tgKey = "r44gfgvss7ee3dkjj";

const Map<String, String> basicHeaders = {
  "Accept": "*/*",
  "Accept-Encoding": "gzip, deflate",
  "Accept-Language": "en-US,en;q=0.9",
  "Connection": "keep-alive",
  "NDCLANG": "en",
  "Content-Type": "application/json; charset=utf-8",
  "User-Agent": UserAgent,
};
