class CropRecommendationService {
  static List<String> recommend(String n, String p, String k, double ph, String soilType) {
    final crops = <String>[];

    // High N + neutral pH → leafy crops
    if (n == 'High' && ph >= 6.0 && ph <= 7.5) crops.addAll(['Kangkong', 'Pechay', 'Lettuce']);
    // High K + medium P → root crops
    if (k == 'High' && p != 'Low') crops.addAll(['Kamote', 'Gabi', 'Carrot']);
    // Balanced NPK → grains
    if (n != 'Low' && p != 'Low' && k != 'Low') crops.addAll(['Corn', 'Rice', 'Soybean']);
    // Low nutrients + acidic → legumes (fix nitrogen naturally)
    if (n == 'Low' && ph < 6.5) crops.addAll(['Mungbean', 'Peanut']);
    // Sandy soil → drought-tolerant
    if (soilType.contains('Sandy')) crops.addAll(['Watermelon', 'Sweet Potato']);
    // Loamy / Clay → broad suitability
    if (soilType.contains('Loamy') || soilType.contains('Clay')) crops.addAll(['Tomato', 'Eggplant', 'Ampalaya']);

    return crops.toSet().take(5).toList(); // deduplicate, max 5
  }
}