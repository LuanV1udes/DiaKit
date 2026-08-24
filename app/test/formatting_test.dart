import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:diakit_app/utils/formatting.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('formatBytes', () {
    test('usa KB e MB com vírgula decimal, como no mockup', () {
      expect(formatBytes(640 * 1024), '640 KB');
      expect(formatBytes((1.4 * 1024 * 1024).round()), '1,4 MB');
    });

    test('omite a casa decimal quando ela não diz nada', () {
      expect(formatBytes(2 * 1024 * 1024), '2 MB');
    });

    test('mantém bytes crus abaixo de 1 KB', () {
      expect(formatBytes(512), '512 B');
    });
  });

  group('dayLabel', () {
    final now = DateTime(2026, 8, 23, 15, 0);

    test('rotula hoje e ontem', () {
      expect(dayLabel(DateTime(2026, 8, 23, 9, 7), now: now), 'Hoje');
      expect(dayLabel(DateTime(2026, 8, 22, 18, 51), now: now), 'Ontem');
    });

    test('usa o dia da semana dentro da última semana', () {
      expect(dayLabel(DateTime(2026, 8, 19), now: now), 'quarta-feira');
    });

    test('usa a data por extenso mais para trás', () {
      expect(dayLabel(DateTime(2026, 7, 4), now: now), '4 de julho');
      expect(dayLabel(DateTime(2025, 12, 31), now: now), '31 de dezembro de 2025');
    });
  });

  test('formatTime segue o relógio de 24h', () {
    expect(formatTime(DateTime(2026, 8, 23, 14, 32)), '14:32');
  });
}
