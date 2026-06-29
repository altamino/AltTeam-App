import 'dart:typed_data';

// Constants
const String apiUrl = "https://service.altamino.top/api/v1";
const String UserAgent = 'Apple iPhone16,1 iOS v15.0 Main/3.22.0';


final Uint8List Prefix = Uint8List.fromList([0x19]);
final String SigKey = "DFA5ED192DDA6E88A12FE12130DC6206B1251E44";
final String DeviceKey = "E7309ECC0953C6FA60005B2765F99DBBC965C8E9";

const Map<String, String> basicHeaders = {
  "Accept": "*/*",
  "Accept-Encoding": "gzip, deflate",
  "Accept-Language": "en-US,en;q=0.9",
  "Connection": "keep-alive",
  "NDCLANG": "en",
  "Content-Type": "application/json; charset=utf-8",
  "User-Agent": UserAgent,
};




const int roleAltAminoMod = 200;
const int roleAltAminoAdmin = 201;
const int roleFeed = 253;
const int roleSystem = 254;
const int roleAltAminoStaff = 555;

const int roleUser = 0;
const int roleCurator = 101;
const int roleLeader = 100;
const int roleAgent = 102;


const List<int> rolesOfAnnouncements = [roleFeed, roleSystem, roleAltAminoStaff];
const List<int> adminRoles = [roleAltAminoMod, roleAltAminoAdmin, roleFeed, roleSystem, roleAltAminoStaff];
const List<int> ndcAdminRoles = [roleCurator, roleLeader, roleAgent];