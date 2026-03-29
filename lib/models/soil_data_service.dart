import 'soil_result.dart';

/// Simple in-memory singleton that keeps results & notes alive across screens.
class SoilDataService {
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

  void addResult(SoilResult r) => results.insert(0, r);
  void removeResult(int i) => results.removeAt(i);

  void addNote(Map<String, String> note) => notes.insert(0, note);
  void updateNote(int i, Map<String, String> note) => notes[i] = note;
  void removeNote(int i) => notes.removeAt(i);

  int get resultsCount => results.length;
  int get notesCount => notes.length;
}
