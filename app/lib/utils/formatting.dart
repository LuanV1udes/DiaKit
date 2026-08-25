import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Converte o [Locale] ativo do app (`pt`/`en`, ver `localeNotifier`) para o
/// código de locale que o `intl` espera nas três funções abaixo. `pt` vira
/// `pt_BR` porque é a única variante de português que o app oferece.
String intlLocale(Locale locale) => locale.languageCode == 'en' ? 'en' : 'pt_BR';

/// Tamanho de arquivo no formato do mockup: `1,4 MB`, `640 KB`.
///
/// Usa base 1024 e vírgula decimal, com uma casa só quando ela diz alguma coisa
/// (`1 MB`, não `1,0 MB`). [locale] segue a convenção do `intl` (`pt_BR`,
/// `en`, ...) e decide o separador decimal.
String formatBytes(int? bytes, {String locale = 'pt_BR'}) {
  if (bytes == null) return '';
  if (bytes < 1024) return '$bytes B';

  final kb = bytes / 1024;
  if (kb < 1024) return '${_decimal(kb, 0, locale)} KB';

  final mb = kb / 1024;
  if (mb < 1024) return '${_decimal(mb, 1, locale)} MB';

  return '${_decimal(mb / 1024, 1, locale)} GB';
}

String _decimal(double value, int digits, String locale) {
  final rounded = double.parse(value.toStringAsFixed(digits));
  final asInt = rounded.truncateToDouble() == rounded;
  return NumberFormat(asInt ? '#,##0' : '#,##0.#', locale).format(rounded);
}

/// Hora da conversão, como nas linhas do Histórico (`14:32`). O relógio de
/// 24h do skeleton `Hm` não muda com o idioma -- só os separadores mudariam.
String formatTime(DateTime at, {String locale = 'pt_BR'}) =>
    DateFormat.Hm(locale).format(at);

/// Rótulo do grupo de data no Histórico: `Hoje`, `Ontem` ou a data por
/// extenso, no idioma indicado por [locale].
String dayLabel(DateTime at, {DateTime? now, String locale = 'pt_BR'}) {
  final today = _atMidnight(now ?? DateTime.now());
  final day = _atMidnight(at);
  final difference = today.difference(day).inDays;
  final isEnglish = locale.startsWith('en');

  if (difference == 0) return isEnglish ? 'Today' : 'Hoje';
  if (difference == 1) return isEnglish ? 'Yesterday' : 'Ontem';
  if (difference < 7) return DateFormat.EEEE(locale).format(at);
  if (day.year == today.year) {
    return isEnglish
        ? DateFormat('MMMM d', locale).format(at)
        : DateFormat('d \'de\' MMMM', locale).format(at);
  }
  return isEnglish
      ? DateFormat('MMMM d, y', locale).format(at)
      : DateFormat('d \'de\' MMMM \'de\' y', locale).format(at);
}

DateTime _atMidnight(DateTime value) =>
    DateTime(value.year, value.month, value.day);
