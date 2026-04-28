class CropRecommendationService {
  static List<String> recommend(
      String n, String p, String k, double ph, String soilType) {
    final scored = <String, int>{};
    void add(String crop, int pts) =>
        scored[crop] = (scored[crop] ?? 0) + pts;

    // ── 1. pH-based suitability (BSWM official bands) ────────────────────────

    // Strongly Acid (< 4.5) — only highly acid-tolerant crops
    if (ph < 4.5) {
      add('Cassava', 2); add('Pineapple', 2);
    }
    // Extremely Acid (4.6–5.0) — limited crop options
    if (ph >= 4.6 && ph <= 5.0) {
      add('Cassava', 3); add('Camote', 2); add('Pineapple', 2);
    }
    // Very Strongly Acid (5.1–5.5) — moderately high suitability
    if (ph >= 5.1 && ph <= 5.5) {
      add('Camote', 3); add('Kangkong', 2); add('Pechay', 2);
      add('Mustasa', 2); add('Gabi', 2);  add('Mungbean', 2);
      add('Peanut', 2); add('Cassava', 1);
    }
    // Moderately to Slightly Acid (5.6–6.8) — HIGH/OPTIMAL per BSWM
    // This is the broadest and most suitable range for Philippine crops
    if (ph >= 5.6 && ph <= 6.8) {
      add('Corn', 3);     add('Rice', 3);     add('Soybean', 3);
      add('Tomato', 3);   add('Eggplant', 3); add('Ampalaya', 3);
      add('Kangkong', 3); add('Pechay', 3);   add('Mustasa', 2);
      add('Sitaw', 2);    add('Upo', 2);       add('Carrot', 2);
      add('Kamote', 2);   add('Gabi', 2);      add('Mungbean', 2);
      add('Peanut', 2);
    }
    // Slightly upper range (6.5–6.8) — allium/brassica crops still within optimal
    if (ph >= 6.5 && ph <= 6.8) {
      add('Sibuyas', 3); add('Bawang', 3); add('Repolyo', 2);
    }
    // Nearly Neutral to Alkaline (> 6.8) — LOW per BSWM (micronutrient lockout)
    // Only very few alkali-tolerant crops recommended; correction also needed
    if (ph > 6.8) {
      add('Sibuyas', 1); add('Bawang', 1); // marginally tolerant up to ~7.2
      // No other crops added — recommend pH correction first
    }

    // ── 2. NPK-based adjustments ──────────────────────────────────────────────
    if (n == 'High' || n == 'Medium') {
      add('Kangkong', 2); add('Pechay', 2); add('Mustasa', 2);
    }
    if (p == 'High' || p == 'Medium') {
      add('Corn', 2); add('Tomato', 2); add('Soybean', 1); add('Rice', 1);
    }
    if (k == 'High' || k == 'Medium') {
      add('Kamote', 2); add('Gabi', 2); add('Saging na Saba', 2);
    }
    // Low N → nitrogen-fixing legumes (BSWM: grow legumes to restore N naturally)
    if (n == 'Low') {
      add('Mungbean', 3); add('Peanut', 3); add('Soybean', 2); add('Sitaw', 1);
    }

    // ── 3. Soil type adjustments (BSWM Soil-Crop Suitability) ────────────────
    if (soilType.contains('Sandy')) {
      add('Camote', 2); add('Peanut', 2); add('Watermelon', 2); add('Cassava', 2);
    }
    if (soilType.contains('Clay')) {
      add('Rice', 3); add('Gabi', 2); add('Kangkong', 2);
    }
    if (soilType.contains('Loam') || soilType.contains('Loamy')) {
      add('Tomato', 2); add('Eggplant', 2); add('Ampalaya', 2);
      add('Corn', 2);   add('Sitaw', 1);
    }
    if (soilType.contains('Silty')) {
      add('Rice', 2); add('Kangkong', 2); add('Pechay', 1);
    }
    if (soilType.contains('Peaty')) {
      add('Cassava', 2); add('Camote', 2);
    }

    if (scored.isEmpty) return [];

    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }
}