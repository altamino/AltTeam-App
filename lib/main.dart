import 'package:flutter/material.dart';

void main() {
  runApp(const AltTeamApp());
}

class AltTeamApp extends StatefulWidget {
  const AltTeamApp({super.key});

  @override
  State<AltTeamApp> createState() => _AltTeamAppState();
}

class _AltTeamAppState extends State<AltTeamApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  void _setTheme(ThemeMode mode) => setState(() => _themeMode = mode);
  void _setLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
          seedColor: const Color.fromARGB(255, 27, 32, 100),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: LoginPage(onSetTheme: _setTheme, onSetLocale: _setLocale),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onSetTheme, required this.onSetLocale});

  final void Function(ThemeMode) onSetTheme;
  final void Function(Locale) onSetLocale;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  ThemeMode _themeMode = ThemeMode.system;
  String _lang = 'en';

  void _login() {
    // TODO
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'AltTeam',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Administration Panel',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _login,
                  child: const Text('Log in'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: _lang,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('🇬🇧 EN')),
                      DropdownMenuItem(value: 'ru', child: Text('🇷🇺 RU')),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _lang = val);
                      widget.onSetLocale(Locale(val));
                    },
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<ThemeMode>(
                    value: _themeMode,
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('🖥 System')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('☀️ Light')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('🌙 Dark')),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _themeMode = val);
                      widget.onSetTheme(val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}