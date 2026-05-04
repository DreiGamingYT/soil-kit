import 'dart:ui';

enum SoilTestType { nitrogen, phosphorus, potassium, ph }

extension SoilTestTypeExt on SoilTestType {
  String get label {
    switch (this) {
      case SoilTestType.nitrogen:   return 'Nitrogen (N)';
      case SoilTestType.phosphorus: return 'Phosphorus (P)';
      case SoilTestType.potassium:  return 'Potassium (K)';
      case SoilTestType.ph:         return 'pH Level';
    }
  }
  String get shortLabel {
    switch (this) {
      case SoilTestType.nitrogen:   return 'N';
      case SoilTestType.phosphorus: return 'P';
      case SoilTestType.potassium:  return 'K';
      case SoilTestType.ph:         return 'pH';
    }
  }
  Color get color {
    switch (this) {
      case SoilTestType.nitrogen:   return const Color(0xFF4CAF50);
      case SoilTestType.phosphorus: return const Color(0xFFFF9800);
      case SoilTestType.potassium:  return const Color(0xFF9C27B0);
      case SoilTestType.ph:         return const Color(0xFF2196F3);
    }
  }
}

class SoilResult {
  final String soilType;
  final DateTime date;
  final double overallScore;
  final String status;
  final String nitrogenLevel;
  final String phosphorusLevel;
  final String potassiumLevel;
  final double ph;
  final String? imagePath;

  final bool isHeuristic;
  final SoilTestType? testType;

  SoilResult({
    required this.soilType,
    required this.date,
    required this.overallScore,
    required this.status,
    required this.nitrogenLevel,
    required this.phosphorusLevel,
    required this.potassiumLevel,
    required this.ph,
    this.imagePath,
    this.isHeuristic = false,
    this.testType,
  });

  String get phDescription {
    if (ph < 4.5)  return 'Strongly Acid';
    if (ph <= 5.0) return 'Extremely Acid';
    if (ph <= 5.5) return 'Very Strongly Acid';
    if (ph <= 6.5) return 'Moderately to Slightly Acid';
    if (ph <= 7.5) return 'Near Neutral';
    return 'Alkaline';
  }

  // Crop suitability rating per BSWM (for UI badges / colour coding)
  String get phSuitability {
    if (ph < 4.5)  return 'Low';
    if (ph <= 5.0) return 'Moderately Low';
    if (ph <= 5.5) return 'Moderately High';
    if (ph <= 7.5) return 'High';
    return 'Low';
  }

  // True only when pH is in BSWM's optimal range
  bool get phIsOptimal => ph >= 5.6 && ph <= 7.5;
}
