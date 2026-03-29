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
    if (ph < 6.0) return 'Acidic';
    if (ph <= 7.0) return 'Slightly Acidic';
    if (ph <= 7.5) return 'Neutral';
    return 'Alkaline';
  }
}
