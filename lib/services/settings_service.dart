import 'package:flutter/material.dart';
import '../l10n/app_translations.dart';

/// App-wide settings singleton using ValueNotifiers so UI rebuilds reactively.
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  // Display
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
  final ValueNotifier<String> measurementUnit = ValueNotifier('mg/kg');
  final ValueNotifier<String> language = ValueNotifier('English');

  // Camera
  final ValueNotifier<bool> autoAnalyze = ValueNotifier(true);
  final ValueNotifier<bool> autoSavePhotos = ValueNotifier(false);

  // Notifications
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier(true);
  final ValueNotifier<bool> notificationPermissionGranted = ValueNotifier(false);

  bool get isDark => themeMode.value == ThemeMode.dark;

  void toggleDarkMode(bool on) {
    themeMode.value = on ? ThemeMode.dark : ThemeMode.light;
  }

  // ── Translation helper ────────────────────────────────────────────────────
  /// Translate a key using the currently selected language.
  String tr(String key) => AppTranslations.t(key, language.value);

  // ── Unit conversion ───────────────────────────────────────────────────────
  // Base unit is always mg/kg internally.
  // ppm    : 1:1   (mg/kg ≡ ppm in soil science)
  // g/L    : ÷ 1000 (approximate; assumes bulk density ~1 kg/L)
  // cmol/kg: ÷ 10  (simplified display conversion)
  static const Map<String, double> _conversionFactor = {
    'mg/kg':   1.0,
    'ppm':     1.0,
    'g/L':     0.001,
    'cmol/kg': 0.1,
  };

  static const Map<String, int> _decimalPlaces = {
    'mg/kg':   0,
    'ppm':     0,
    'g/L':     3,
    'cmol/kg': 2,
  };

  /// Convert a raw mg/kg value to the currently selected unit.
  double convertValue(double mgPerKg) {
    final factor = _conversionFactor[measurementUnit.value] ?? 1.0;
    return mgPerKg * factor;
  }

  /// Format a mg/kg value for display in the current unit (e.g. "25" or "0.025").
  String formatValue(double mgPerKg) {
    final converted = convertValue(mgPerKg);
    final dp = _decimalPlaces[measurementUnit.value] ?? 0;
    return converted.toStringAsFixed(dp);
  }

  /// The current unit label string, e.g. 'mg/kg' or 'ppm'.
  String get unitLabel => measurementUnit.value;

  static const List<String> availableUnits = ['mg/kg', 'ppm', 'g/L', 'cmol/kg'];
}