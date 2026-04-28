import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalibrationService {
  static const _kCalibration   = 'calibration';
  static const _kWhiteRef      = 'white_reference';

  // ── Nutrient calibration ───────────────────────────────────────────────────

  /// Saves calibration data (averaged RGB per nutrient per level).
  Future<void> saveCalibration(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCalibration, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_kCalibration);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // ── White reference patch (Feature 3) ─────────────────────────────────────

  /// Persists the white-reference RGB captured from a blank/white card.
  Future<void> saveWhiteReference(List<double> rgb) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWhiteRef, jsonEncode(rgb));
  }

  /// Returns the stored white-reference [r, g, b], or null if not yet captured.
  Future<List<double>?> loadWhiteReference() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kWhiteRef);
    if (raw == null) return null;
    final list = (jsonDecode(raw) as List).cast<num>();
    return list.map((v) => v.toDouble()).toList();
  }

  Future<void> clearWhiteReference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kWhiteRef);
  }
}