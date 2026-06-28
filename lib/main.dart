import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/router.dart';
import 'core/l10n/app_localizations.dart';
import 'core/storage.dart';
import 'core/api/network/api.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  await Api.init();
  await AppLocalizations.load(Storage.locale);
  runApp(const AltTeamApp());
}

class AltTeamApp extends StatefulWidget {
  const AltTeamApp({super.key});
  @override
  State<AltTeamApp> createState() => _AltTeamAppState();
}

class _AltTeamAppState extends State<AltTeamApp> {
  late ThemeMode _themeMode;
  late Locale _locale;


  late final GoRouter _router = buildRouter(
    onSetTheme: _setTheme,
    onSetLocale: _setLocale,
  );

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

    _themeMode = Storage.themeMode;
    _locale = Locale(Storage.locale);
  }

  void _setTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
    Storage.setThemeMode(mode);
  }

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
    Storage.setLocale(locale.languageCode);
    AppLocalizations.load(locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AltTeam',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      locale: _locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}