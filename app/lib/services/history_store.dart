import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/conversion_entry.dart';

/// Histórico de conversões, persistido em [SharedPreferences].
///
/// É um [ChangeNotifier] único para o app inteiro: a tela Converter grava e a
/// aba Histórico se redesenha sozinha, sem precisar recarregar ao trocar de aba.
class HistoryStore extends ChangeNotifier {
  HistoryStore._();

  static final HistoryStore instance = HistoryStore._();

  static const _key = 'conversion_history';

  /// Limite de linhas guardadas -- o mockup não pagina o histórico.
  static const _maxEntries = 100;

  List<ConversionEntry> _entries = const [];
  bool _loaded = false;

  /// Do mais recente para o mais antigo.
  List<ConversionEntry> get entries => List.unmodifiable(_entries);

  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];

    _entries = raw
        .map((line) {
          try {
            return ConversionEntry.decode(line);
          } catch (_) {
            // Linha gravada por uma versão anterior do modelo: ignora em vez de
            // derrubar a tela inteira.
            return null;
          }
        })
        .nonNulls
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));

    _loaded = true;
    notifyListeners();
  }

  Future<void> add(ConversionEntry entry) async {
    _entries = [entry, ..._entries];
    if (_entries.length > _maxEntries) {
      _entries = _entries.sublist(0, _maxEntries);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _entries = const [];
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _entries.map((e) => e.encode()).toList());
  }
}
