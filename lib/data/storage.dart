import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

/// Guarda o [Notebook] (um único JSON) e a escolha de tema.
class Storage {
  Storage(this._prefs);
  final SharedPreferences _prefs;

  static const notebookKey = 'diario.notebook';
  static const themeKey = 'diario.theme';

  Notebook loadNotebook() {
    final raw = _prefs.getString(notebookKey);
    if (raw == null) return const Notebook();
    try {
      return Notebook.fromJson(jsonDecode(raw));
    } catch (_) {
      return const Notebook();
    }
  }

  Future<void> saveNotebook(Notebook nb) =>
      _prefs.setString(notebookKey, jsonEncode(nb.toJson()));

  Future<void> clearNotebook() => _prefs.remove(notebookKey);

  ThemeMode loadTheme() {
    final v = _prefs.getString(themeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == v,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> saveTheme(ThemeMode m) => _prefs.setString(themeKey, m.name);
}
