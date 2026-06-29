import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';


import '../screens/login.dart';
import '../screens/welcome.dart';
import  '../screens/admin_profile.dart';
import  '../screens/main/adm_link_mod.dart';
import  '../screens/main/adm_password_reset.dart';
import  '../screens/main/adm_report.dart';
import  '../screens/main/adm_roles.dart';
import  '../screens/main/adm_search.dart';
import  '../screens/main/admin_dashboard.dart';
import  '../screens/main/team.dart';
import  '../screens/main/create_announcement.dart';
import  '../screens/main/notification.dart';

import 'storage.dart';


GoRouter buildRouter({
  required void Function(ThemeMode) onSetTheme,
  required void Function(Locale) onSetLocale,
}) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final sid = Storage.sid;
      final isLogin = state.matchedLocation == '/login';
      if (sid != null && isLogin) return '/welcome';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          onSetTheme: onSetTheme,
          onSetLocale: onSetLocale,
        ),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => ProfileScreen(
          onSetTheme: onSetTheme,
          onSetLocale: onSetLocale,
        ),
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/reports', builder: (context, state) => const AdminReportsScreen()),
      GoRoute(path: '/admin/links', builder: (context, state) => const AdminLinkModerationScreen()),
      GoRoute(path: '/admin/password-reset', builder: (context, state) => const AdminPasswordResetScreen()),
      GoRoute(path: '/admin/roles', builder: (context, state) => const AdminRolesScreen()),
      GoRoute(path: '/admin/search', builder: (context, state) => const AdminSearchScreen()),
      GoRoute(path: '/admin/team', builder: (context, state) => const AdminTeamScreen()),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/admin/announcements/create', builder: (context, state) => const AdminCreateAnnouncementScreen()),   
    
    ],
  );
}