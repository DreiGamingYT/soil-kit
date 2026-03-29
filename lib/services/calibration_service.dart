import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalibrationService {

  Future<void> saveCalibration(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("calibration", jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString("calibration");

    if(data == null) return null;
    return jsonDecode(data);
  }
}