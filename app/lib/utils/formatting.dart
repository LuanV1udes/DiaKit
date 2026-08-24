import 'package:intl/intl.dart';

/// Tamanho de arquivo no formato do mockup: `1,4 MB`, `640 KB`.
///
/// Usa base 1024 e vírgula decimal, com uma casa só quando ela diz alguma coisa
/// (`1 MB`, não `1,0 MB`).
String formatBytes(int? bytes) {
  if (bytes == null) return '';
  if (bytes < 1024) return '$bytes B';

  final kb = bytes / 1024;
  if (kb < 1024) return '${_decimal(kb, 0)} KB';

  final mb = kb / 1024;
  if (mb < 1024) return '${_decimal(mb, 1)} MB';

  return '${_decimal(mb / 1024, 1)} GB';
}

String _decimal(double value, int digits) {
  final rounded = double.parse(value.toStringAsFixed(digits));
  final asInt = rounded.truncateToDouble() == rounded;
  return NumberFormat(asInt ? '#,##0' : '#,##0.#', 'pt_BR').format(rounded);
}

/// Hora da conversão, como nas linhas do Histórico (`14:32`).
String formatTime(DateTime at) => DateFormat.Hm('pt_BR').format(at);

/// Rótulo do grupo de data no Histórico: `Hoje`, `Ontem` ou a data por extenso.
String dayLabel(DateTime at, {DateTime? now}) {
  final today = _atMidnight(now ?? DateTime.now());
  final day = _atMidnight(at);
  final difference = today.difference(day).inDays;

  if (difference == 0) return 'Hoje';
  if (difference == 1) return 'Ontem';
  if (difference < 7) return DateFormat.EEEE('pt_BR').format(at);
  if (day.year == today.year) return DateFormat('d \'de\' MMMM', 'pt_BR').format(at);
  return DateFormat('d \'de\' MMMM \'de\' y', 'pt_BR').format(at);
}

DateTime _atMidnight(DateTime value) =>
    DateTime(value.year, value.month, value.day);
