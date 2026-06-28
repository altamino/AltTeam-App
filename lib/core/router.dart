import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../screens/login.dart';
import '../screens/welcome.dart';
import  '../screens/admin_profile.dart';
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
    ],
  );
}