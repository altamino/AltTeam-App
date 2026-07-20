import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class Storage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }


  static ThemeMode get themeMode {
    final val = _prefs?.getString('theme') ?? 'system';
    return switch (val) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final val = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await _prefs?.setString('theme', val);
  }

  static String get locale => _prefs?.getString('locale') ?? 'en';
  static Future<void> setLocale(String code) => 
      _prefs?.setString('locale', code) ?? Future.value();


  static String? get sid => _prefs?.getString('sid');
  static String? get userId => _prefs?.getString('userId');
  static String? get deviceId => _prefs?.getString('deviceId');
  static int? get role => _prefs?.getInt('role');
  static String? get aminoId => _prefs?.getString('aminoId');
  static int? get telegramId => _prefs?.getInt('telegramId');

  static String? get email => _prefs?.getString('email');
  static String? get secret => _prefs?.getString('secret');


  static Future<void> setSid(String sid) => 
      _prefs?.setString('sid', sid) ?? Future.value();
  static Future<void> setUserId(String uid) => 
      _prefs?.setString('userId', uid) ?? Future.value();
  static Future<void> setDeviceId(String id) => 
      _prefs?.setString('deviceId', id) ?? Future.value();
  static Future<void> setEmail(String email) => 
      _prefs?.setString('email', email) ?? Future.value();
  static Future<void> setSecret(String secret) => 
      _prefs?.setString('secret', secret) ?? Future.value();
  static Future<void> setRole(int role) => 
      _prefs?.setInt('role', role) ?? Future.value();
  static Future<void> setTelegramId(int? telegramId) async {
    if (telegramId != null) {
      await _prefs?.setInt('telegramId', telegramId);
    } else {
      await _prefs?.remove('telegramId');
    }
  }
  static Future<void> setAminoId(String aminoId) => 
      _prefs?.setString('aminoId', aminoId) ?? Future.value();
      
  static Future<void> clearSession() async {
    await _prefs?.remove('sid');
    await _prefs?.remove('userId');
    await _prefs?.remove('role');
    await _prefs?.remove('aminoId');
    await _prefs?.remove('telegramId');
    await _prefs?.remove('email');
    await _prefs?.remove('secret');
  }
}