import '../models/soil_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple in-memory singleton that keeps results & notes alive across screens.
class SoilDataService {
  final List<SoilResult> _pendingSync = [];
  bool get hasPendingSync => _pendingSync.isNotEmpty;
  SoilDataService._();
  static final SoilDataService instance = SoilDataService._();

  // Soil test history — pre-seeded with sample data
  final List<SoilResult> results = [
    SoilResult(
      soilType: 'Clay Loam',
      date: DateTime(2026, 2, 16),
      overallScore: 34,
      status: 'Critical Low Nutrient',
      nitrogenLevel: 'Low',
      phosphorusLevel: 'Medium',
      potassiumLevel: 'High',
      ph: 6.2,
    ),
    SoilResult(
      soilType: 'Sandy Soil',
      date: DateTime(2026, 2, 9),
      overallScore: 58,
      status: 'Moderate Nutrient',
      nitrogenLevel: 'Medium',
      phosphorusLevel: 'Medium',
      potassiumLevel: 'Medium',
      ph: 6.8,
    ),
    SoilResult(
      soilType: 'Silty Clay',
      date: DateTime(2026, 2, 1),
      overallScore: 72,
      status: 'Good Nutrient Level',
      nitrogenLevel: 'High',
      phosphorusLevel: 'Medium',
      potassiumLevel: 'High',
      ph: 7.1,
    ),
    SoilResult(
      soilType: 'Loamy Soil',
      date: DateTime(2026, 1, 19),
      overallScore: 45,
      status: 'Low Nutrient',
      nitrogenLevel: 'Low',
      phosphorusLevel: 'Low',
      potassiumLevel: 'Medium',
      ph: 5.9,
    ),
  ];

  // Notes
  final List<Map<String, String>> notes = [
    {
      'title': 'Field A Observation',
      'body': 'Soil looks dry. Need more irrigation.',
      'date': 'Mar 1, 2026'
    },
    {
      'title': 'Fertilizer Schedule',
      'body': 'Apply NPK fertilizer every 3 weeks.',
      'date': 'Feb 20, 2026'
    },
  ];

  Future<void> addResult(SoilResult r, {bool saveToFirestore = true}) async {
    results.insert(0, r);
    final prefs = await SharedPreferences.getInstance();
    // persist locally (simple JSON list of scores for now)
    final encoded = results.map((s) => jsonEncode({
      'soilType': s.soilType,
      'date': s.date.toIso8601String(),
      'overallScore': s.overallScore,
      'status': s.status,
      'nitrogenLevel': s.nitrogenLevel,
      'phosphorusLevel': s.phosphorusLevel,
      'potassiumLevel': s.potassiumLevel,
      'ph': s.ph,
      'imagePath': s.imagePath,
    })).toList();
    await prefs.setStringList('soil_results', encoded);

    if (!saveToFirestore) _pendingSync.add(r);
  }

  // Add in soil_data_service.dart after the addResult() method
  Future<void> syncPending(FirebaseFirestore db) async {
    final toSync = List<SoilResult>.from(_pendingSync);
    for (final r in toSync) {
      try {
        await db.collection('soil_results').add({
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'soilType': r.soilType,
          'date': r.date.toIso8601String(),
          'overallScore': r.overallScore,
          'status': r.status,
          'nitrogenLevel': r.nitrogenLevel,
          'phosphorusLevel': r.phosphorusLevel,
          'potassiumLevel': r.potassiumLevel,
          'ph': r.ph,
        });
        _pendingSync.remove(r);
      } catch (_) {}
    }
  }

// Add a new method after addResult:
  Future<void> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('soil_results') ?? [];
    if (raw.isEmpty) return; // keep sample data if nothing stored yet
    results
      ..clear()
      ..addAll(raw.map((e) {
        final m = jsonDecode(e) as Map<String, dynamic>;
        return SoilResult(
          soilType: m['soilType'],
          date: DateTime.parse(m['date']),
          overallScore: (m['overallScore'] as num).toDouble(),
          status: m['status'],
          nitrogenLevel: m['nitrogenLevel'],
          phosphorusLevel: m['phosphorusLevel'],
          potassiumLevel: m['potassiumLevel'],
          ph: (m['ph'] as num).toDouble(),
          imagePath: m['imagePath'],
        );
      }));
  }

  void removeResult(int i) => results.removeAt(i);

  void addNote(Map<String, String> note) => notes.insert(0, note);
  void updateNote(int i, Map<String, String> note) => notes[i] = note;
  void removeNote(int i) => notes.removeAt(i);

  int get resultsCount => results.length;
  int get notesCount => notes.length;
}
