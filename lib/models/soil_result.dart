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
  });

  String get phDescription {
    if (ph < 4.5)  return 'Strongly Acid';
    if (ph <= 5.0) return 'Extremely Acid';
    if (ph <= 5.5) return 'Very Strongly Acid';
    if (ph <= 6.8) return 'Moderately to Slightly Acid';
    return 'Nearly Neutral to Alkaline';
  }

  // Crop suitability rating per BSWM (for UI badges / colour coding)
  String get phSuitability {
    if (ph < 4.5)  return 'Low';
    if (ph <= 5.0) return 'Moderately Low';
    if (ph <= 5.5) return 'Moderately High';
    if (ph <= 6.8) return 'High';
    return 'Low';
  }

  // True only when pH is in BSWM's optimal range
  bool get phIsOptimal => ph >= 5.6 && ph <= 6.8;
}
