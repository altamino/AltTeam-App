import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/router.dart';
import 'core/l10n/app_localizations.dart';
import 'core/storage.dart';
import 'core/api/network/api.dart';
import 'core/api/repositories/version_check.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Storage.init();
    await Api.init();
    await AppLocalizations.load(Storage.locale);
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _SplashScreen(),
      );
    }
    return const AltTeamApp();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 120),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
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
    _checkVersion();
  }

Future<void> _checkVersion() async {
  final result = await VersionCheck.check();
  final parsedOk = result.latestVersion.isNotEmpty;
  if (parsedOk && !result.isUpToDate) {
    if (mounted) {
      _router.go('/update-required', extra: result.downloadPage);
    }
  }
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 181, 237, 240)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 23, 39, 38),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}