// Gera os PNGs de `test/previews/` para conferir as telas contra o handoff.
//
// Fica fora da suíte normal (imagens quebram a cada mudança de fonte ou de
// versão do Flutter). Para regerar:
//
//   DIAKIT_PREVIEWS=1 flutter test test/preview_test.dart --update-goldens
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diakit_app/screens/app_shell.dart';
import 'package:diakit_app/screens/convert_screen.dart';
import 'package:diakit_app/screens/history_screen.dart';
import 'package:diakit_app/screens/profile_screen.dart';
import 'package:diakit_app/screens/result_screen.dart';
import 'package:diakit_app/screens/splash_screen.dart';
import 'package:diakit_app/services/converter_client.dart';
import 'package:diakit_app/services/history_store.dart';
import 'package:diakit_app/theme/app_theme.dart';

/// Guarda que mantém os previews fora do `flutter test` do dia a dia.
final _enabled = Platform.environment['DIAKIT_PREVIEWS'] == '1';

const _mobile = Size(390, 844);
const _desktop = Size(1280, 800);

String _entry(String name, DateTime at, String status, int? size, String? msg) =>
    jsonEncode({
      'fileName': name,
      'at': at.toIso8601String(),
      'status': status,
      'pdfPath': null,
      'sizeBytes': size,
      'errorMessage': msg,
    });

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Widget child, {
  Size size = _mobile,
  Brightness brightness = Brightness.light,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = 2;

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size, platformBrightness: brightness),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byType(MaterialApp), matchesGoldenFile('previews/$name.png'));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    await _loadFonts();
  });

  setUp(() async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'onboarding_seen': true,
      'conversion_history': [
        _entry('Relatório_Trimestral.pdf', now.subtract(const Duration(hours: 2)),
            'success', 1258291, null),
        _entry('Contrato_Aluguel.pdf', now.subtract(const Duration(hours: 7)),
            'success', 655360, null),
        _entry('Curriculo_2026.pdf', now.subtract(const Duration(days: 1)),
            'success', 389120, null),
        _entry('Proposta_Comercial.docx', now.subtract(const Duration(days: 1, hours: 4)),
            'error', null, 'O servidor não conseguiu converter o arquivo.'),
      ],
    });
    await HistoryStore.instance.load();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'claro' : 'escuro';

    testWidgets('01-splash-$suffix', (tester) async {
      await _shoot(tester, '01-splash-$suffix',
          SplashScreen(onStart: () {}), brightness: brightness);
    }, skip: !_enabled);

    testWidgets('02-home-$suffix', (tester) async {
      await _shoot(tester, '02-home-$suffix', const AppShell(),
          brightness: brightness);
    }, skip: !_enabled);

    testWidgets('03-converter-$suffix', (tester) async {
      await _shoot(tester, '03-converter-$suffix',
          const Scaffold(body: ConvertScreen()), brightness: brightness);
    }, skip: !_enabled);

    testWidgets('04-resultado-$suffix', (tester) async {
      await _shoot(
        tester,
        '04-resultado-$suffix',
        Scaffold(
          body: ResultScreen(
            output: ConversionOutput(
              file: File('Relatório_Trimestral.pdf'),
              sizeBytes: 1258291,
            ),
          ),
        ),
        brightness: brightness,
      );
    }, skip: !_enabled);

    testWidgets('05-historico-$suffix', (tester) async {
      await _shoot(tester, '05-historico-$suffix',
          const Scaffold(body: HistoryScreen()), brightness: brightness);
    }, skip: !_enabled);

    testWidgets('06-perfil-$suffix', (tester) async {
      await _shoot(tester, '06-perfil-$suffix',
          const Scaffold(body: ProfileScreen()), brightness: brightness);
    }, skip: !_enabled);
  }

  testWidgets('13-desktop-home', (tester) async {
    await _shoot(tester, '13-desktop-home', const AppShell(), size: _desktop);
  }, skip: !_enabled);

  testWidgets('16-desktop-historico', (tester) async {
    await _shoot(tester, '16-desktop-historico',
        const Scaffold(body: HistoryScreen()), size: _desktop);
  }, skip: !_enabled);

  testWidgets('17-desktop-perfil-escuro', (tester) async {
    await _shoot(tester, '17-desktop-perfil-escuro',
        const Scaffold(body: ProfileScreen()),
        size: _desktop, brightness: Brightness.dark);
  }, skip: !_enabled);
}

/// Carrega Josefin Sans e o icon font do Lucide para que os previews mostrem a
/// tipografia real em vez da fonte de teste.
Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      loader.addFont(
        File(path).readAsBytes().then((b) => ByteData.view(b.buffer)),
      );
    }
    await loader.load();
  }

  await load('JosefinSans', [
    'assets/fonts/JosefinSans-Regular.ttf',
    'assets/fonts/JosefinSans-Medium.ttf',
    'assets/fonts/JosefinSans-SemiBold.ttf',
    'assets/fonts/JosefinSans-Bold.ttf',
  ]);

  final lucide = File(
    '${Platform.environment['LOCALAPPDATA']}/Pub/Cache/hosted/pub.dev/'
    'lucide_icons_flutter-3.1.17/assets/lucide.ttf',
  );
  if (lucide.existsSync()) {
    await load('packages/lucide_icons_flutter/Lucide', [lucide.path]);
  }
}
