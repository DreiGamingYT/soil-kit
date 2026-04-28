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

  /// True when NPK and pH were estimated via the RGB heuristic fallback
  /// (i.e. no calibration data was present at analysis time).
  /// Results in this state are unreliable and must be clearly flagged to the user.
  final bool isHeuristic;

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
