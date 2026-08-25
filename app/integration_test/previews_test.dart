// Gera previews das telas rodando na engine real do Windows/macOS/Linux, e não
// na fonte de teste do `flutter test`.
//
// É o único jeito de conferir o que depende do sistema — em especial o fallback
// de fonte para glifos que Josefin Sans não tem (a seta de "PDF → Word").
//
//   flutter test integration_test/previews_test.dart -d windows
//
// As imagens saem em `build/previews/`.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diakit_app/l10n/generated/app_localizations.dart';
import 'package:diakit_app/screens/app_shell.dart';
import 'package:diakit_app/theme/app_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final dir = Directory('build/previews');

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    dir.createSync(recursive: true);
  });

  setUp(() => SharedPreferences.setMockInitialValues({'onboarding_seen': true}));

  Future<void> shoot(
    WidgetTester tester,
    String name, {
    required Size size,
    Brightness brightness = Brightness.light,
  }) async {
    await tester.binding.setSurfaceSize(size);

    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MediaQuery(
          data: MediaQueryData(size: size, platformBrightness: brightness),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: brightness == Brightness.light
                ? AppTheme.light
                : AppTheme.dark,
            locale: const Locale('pt'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AppShell(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('${dir.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  }

  testWidgets('home mobile', (tester) async {
    await shoot(tester, 'engine-home-mobile', size: const Size(390, 844));
  });

  testWidgets('home desktop', (tester) async {
    await shoot(tester, 'engine-home-desktop', size: const Size(1280, 800));
  });

  testWidgets('home mobile escuro', (tester) async {
    await shoot(
      tester,
      'engine-home-mobile-escuro',
      size: const Size(390, 844),
      brightness: Brightness.dark,
    );
  });
}
