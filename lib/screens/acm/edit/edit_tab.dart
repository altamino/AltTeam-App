import 'package:flutter/material.dart';

import 'edit_community_controller.dart';


abstract class EditTab {
  const EditTab();

  String get id;

  IconData get icon;

  String get titleKey;

  bool get showSaveBar => true;

  Widget build(BuildContext context, EditCommunityController c);
}