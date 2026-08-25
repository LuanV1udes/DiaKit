import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema escolhido nas Configurações, refletido ao vivo no [MaterialApp] de
/// `main.dart` -- carregado do disco uma vez no bootstrap e atualizado a cada
/// troca feita no Perfil.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.system,
);

/// Idioma escolhido nas Configurações, com o mesmo papel do
/// [themeModeNotifier] acima -- o app nunca segue o idioma do sistema, então
/// não existe uma opção "automático" aqui.
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('pt'));

/// Preferências simples do app, guardadas em [SharedPreferences].
class SettingsStore {
  static const _serverUrlKey = 'server_url';
  static const _onboardingSeenKey = 'onboarding_seen';
  static const _themeModeKey = 'theme_mode';
  static const _localeKey = 'locale';

  /// Endereço padrão do serviço de conversão (o backend Node em `backend/`).
  static const defaultServerUrl = 'http://localhost:4123';

  Future<String> serverUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_serverUrlKey);
    return (stored == null || stored.isEmpty) ? defaultServerUrl : stored;
  }

  Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url.trim());
  }

  /// A Splash só aparece na primeira abertura.
  Future<bool> onboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }

  /// Tema salvo, ou [ThemeMode.system] (o padrão do app) se nunca escolhido.
  Future<ThemeMode> themeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(_themeModeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  /// Idioma salvo, ou português (o padrão do app) se nunca escolhido.
  Future<Locale> locale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) == 'en'
        ? const Locale('en')
        : const Locale('pt');
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}
