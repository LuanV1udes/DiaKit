import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/app_shell.dart';
import 'screens/splash_screen.dart';
import 'services/history_store.dart';
import 'services/settings_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Os rótulos de data do Histórico ("Hoje", "12 de agosto") vêm do intl.
  await initializeDateFormatting('pt_BR');
  runApp(const DiaKitApp());
}

class DiaKitApp extends StatelessWidget {
  const DiaKitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiaKit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // As duas variantes do handoff acompanham a preferência do sistema.
      themeMode: ThemeMode.system,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _Bootstrap(),
    );
  }
}

/// Carrega o estado inicial e decide entre a Splash e o app propriamente dito.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  final _settings = SettingsStore();

  bool _ready = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seen = await _settings.onboardingSeen();
    await HistoryStore.instance.load();

    if (!mounted) return;
    setState(() {
      _showSplash = !seen;
      _ready = true;
    });
  }

  Future<void> _start() async {
    await _settings.markOnboardingSeen();
    if (mounted) setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto lê as preferências mostramos o fundo do tema, sem spinner: a
    // leitura dura um frame ou dois e um indicador só piscaria na tela.
    if (!_ready) return const Scaffold(body: SizedBox.expand());

    return _showSplash ? SplashScreen(onStart: _start) : const AppShell();
  }
}
