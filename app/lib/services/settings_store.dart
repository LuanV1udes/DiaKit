import 'package:shared_preferences/shared_preferences.dart';

/// Preferências simples do app, guardadas em [SharedPreferences].
class SettingsStore {
  static const _serverUrlKey = 'server_url';
  static const _onboardingSeenKey = 'onboarding_seen';

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
}
