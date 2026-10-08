abstract class RoleTypes {

  static const int roleAltAminoMod = 200;
  static const int roleAltAminoAdmin = 201;
  static const int roleFeed = 253;
  static const int roleSystem = 254;
  static const int roleAltAminoStaff = 555;


  static const int roleUser = 0;
  static const int roleLeader = 100;
  static const int roleCurator = 101;
  static const int roleAgent = 102;


  static const List<int> rolesOfAnnouncements = [roleFeed, roleSystem, roleAltAminoStaff];
  static const List<int> adminRoles = [roleAltAminoMod, roleAltAminoAdmin, roleFeed, roleSystem, roleAltAminoStaff];
  static const List<int> ndcAdminRoles = [roleCurator, roleLeader, roleAgent];
  static const List<int> ndcMainAdminRoles = [roleLeader, roleAgent];

  static bool isAnnouncementsRole(int? role) {
    return rolesOfAnnouncements.contains(role);
  }

  static bool isStaffRole(int? role) {
    return adminRoles.contains(role);
  }

  static bool isNdcAdminRole(int? role) {
    return ndcAdminRoles.contains(role);
  }

  static bool isNdcMainAdminRole(int? role) {
    return ndcMainAdminRoles.contains(role);
  }
}