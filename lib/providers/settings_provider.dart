import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AppLanguage { fr, en }

enum AppCurrency { eur, usd }

class SettingsState {
  final AppLanguage language;
  final AppCurrency currency;
  final ThemeMode themeMode;

  const SettingsState({
    this.language = AppLanguage.fr,
    this.currency = AppCurrency.eur,
    this.themeMode = ThemeMode.light,
  });

  SettingsState copyWith({
    AppLanguage? language,
    AppCurrency? currency,
    ThemeMode? themeMode,
  }) =>
      SettingsState(
        language: language ?? this.language,
        currency: currency ?? this.currency,
        themeMode: themeMode ?? this.themeMode,
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kLanguage = 'settings_language';
  static const _kCurrency = 'settings_currency';
  static const _kTheme = 'settings_theme';

  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final lang = await _storage.read(key: _kLanguage);
      final curr = await _storage.read(key: _kCurrency);
      final theme = await _storage.read(key: _kTheme);
      state = SettingsState(
        language: lang == 'en' ? AppLanguage.en : AppLanguage.fr,
        currency: curr == 'usd' ? AppCurrency.usd : AppCurrency.eur,
        themeMode: theme == 'dark' ? ThemeMode.dark : ThemeMode.light,
      );
    } catch (_) {}
  }

  Future<void> setLanguage(AppLanguage lang) async {
    await _storage.write(
        key: _kLanguage, value: lang == AppLanguage.en ? 'en' : 'fr');
    state = state.copyWith(language: lang);
  }

  Future<void> setCurrency(AppCurrency currency) async {
    await _storage.write(
        key: _kCurrency, value: currency == AppCurrency.usd ? 'usd' : 'eur');
    state = state.copyWith(currency: currency);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _storage.write(
        key: _kTheme, value: mode == ThemeMode.dark ? 'dark' : 'light');
    state = state.copyWith(themeMode: mode);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
