import '../constants.dart';





bool isStaffRole(int role) {
  return role == roleAltAminoMod ||
      role == roleAltAminoAdmin ||
      role == roleAltAminoStaff;
}
 