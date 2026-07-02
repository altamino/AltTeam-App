import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/adm/chats.dart';
import '../screens/adm/dashboard/admin_dashboard.dart';
import '../screens/adm/dashboard/report.dart';
import '../screens/adm/dashboard/roles.dart';
import '../screens/adm/team.dart';
import '../screens/altacm/create.dart';
import '../screens/altacm/main.dart';
import '../screens/altacm/ndc/community.dart';
import '../screens/altacm/ndc/edit.dart';
import '../screens/login.dart';
import '../screens/main/create_announcement.dart';
import '../screens/main/notification.dart';
import '../screens/main/profile.dart';
import '../screens/main/welcome.dart';
import '../screens/users/report.dart';
import '../screens/adm/dashboard/user_moderation.dart';
//import '../screens/adm/dashboard/events.dart';
import 'storage.dart';

GoRouter buildRouter({
  required void Function(ThemeMode) onSetTheme,
  required void Function(Locale) onSetLocale,
}) {
  return GoRouter(
    initialLocation: '/login',
    
    errorBuilder: (context, state) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/welcome');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    },

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
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(
        path: '/profile', 
        builder: (context, state) => ProfileScreen(onSetTheme: onSetTheme, onSetLocale: onSetLocale),
      ),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/reports', builder: (context, state) => const UserReportsScreen()),
      


      GoRoute(
        path: '/altacm', 
        builder: (context, state) => const AltAcmMainScreen(),
        routes: [
          GoRoute(
            path: 'community/create',
            builder: (context, state) => const AltAcmCreateCommunityScreen(),
          ),
          GoRoute(
            path: 'community/:ndcId',
            builder: (context, state) {
              final ndcId = state.pathParameters['ndcId'] ?? '0';
              return AltAcmCommunityScreen(ndcId: ndcId);
            },
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final data = state.extra as Map<String, dynamic>?;
              return AltAcmEditCommunityScreen(communityData: data);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin', 
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(path: 'reports', builder: (context, state) => const AdminReportsScreen()),
          GoRoute(path: 'roles', builder: (context, state) => const AdminRolesScreen()),
          GoRoute(path: 'team', builder: (context, state) => const AdminTeamScreen()),
          GoRoute(path: 'announcements/create', builder: (context, state) => const AdminCreateAnnouncementScreen()),   
          GoRoute(path: 'chats', builder: (context, state) => const AdminChatsScreen()),
          GoRoute(path: 'user/moderation', builder: (context, state) => const UserModerationScreen()),
          //GoRoute(path: 'events', builder: (context, state) => const EventsModerationScreen()),
        ],
      ),
    ],
  );
}