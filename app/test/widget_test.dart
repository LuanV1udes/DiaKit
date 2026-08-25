import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diakit_app/main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('primeira abertura mostra a Splash', (tester) async {
    await tester.pumpWidget(const DiaKitApp());
    await tester.pumpAndSettle();

    expect(find.text('DiaKit'), findsOneWidget);
    expect(find.text('Começar'), findsOneWidget);
  });

  testWidgets('"Começar" leva para a Home', (tester) async {
    await tester.pumpWidget(const DiaKitApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();

    expect(find.text('O que vamos fazer hoje?'), findsOneWidget);
    expect(find.text('Converter para PDF'), findsOneWidget);
    expect(find.text('Ferramentas'.toUpperCase()), findsOneWidget);
    expect(find.text('PDF → Imagem'), findsOneWidget);
  });

  testWidgets('com o onboarding visto, abre direto no app', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_seen': true});

    await tester.pumpWidget(const DiaKitApp());
    await tester.pumpAndSettle();

    expect(find.text('Começar'), findsNothing);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('"PDF → Imagem" abre o fluxo de rasterização', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_seen': true});

    await tester.pumpWidget(const DiaKitApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('PDF → Imagem'));
    await tester.pumpAndSettle();

    expect(find.text('PDF para Imagem'), findsOneWidget);
    expect(find.text('PDF, até 25MB'), findsOneWidget);
  });

  testWidgets('"CSV e Excel" abre o fluxo de conversão', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_seen': true});

    await tester.pumpWidget(const DiaKitApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('CSV e Excel'));
    await tester.pumpAndSettle();

    expect(find.text('CSV, XLS ou XLSX, até 25MB'), findsOneWidget);
  });

  testWidgets('a tab bar troca de aba', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_seen': true});

    await tester.pumpWidget(const DiaKitApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma conversão por aqui ainda.'), findsOneWidget);
  });

  testWidgets('trocar o idioma para English relocaliza o app inteiro', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_seen': true});

    await tester.pumpWidget(const DiaKitApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Idioma'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Preferences'.toUpperCase()), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('What shall we do today?'), findsOneWidget);
  });
}
