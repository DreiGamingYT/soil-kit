class SoilLogicService {

  int phScore(double ph) {
    if (ph >= 6.0 && ph <= 7.0) return 3;
    if ((ph >= 5.5 && ph < 6.0) || (ph > 7.0 && ph <= 7.5)) return 2;
    return 1;
  }

  int score(String n, String p, String k, {double ph = 6.5}) {
    int value(String level) {
      switch (level.toLowerCase()) {
        case 'high':   return 3;
        case 'medium': return 2;
        case 'low':    return 1;
        default:       return 0;
      }
    }
    return value(n) + value(p) + value(k) + phScore(ph);
  }

  // ── Health label (updated for 4–12 range) ─────────────────────────────────

  String healthLabel(int score) {
    // 4–12 scale: ≥10 healthy, ≥7 moderate, <7 poor
    if (score >= 10) return 'HEALTHY';
    if (score >= 7)  return 'MODERATE';
    return 'POOR';
  }

  // ── Soil type inference ───────────────────────────────────────────────────

  String inferSoilType(String n, String p, String k, double ph) {
    const profiles = <Map<String, dynamic>>[
      {
        'type': 'Clay Soil',
        // Clay binds nutrients tightly → medium-to-high NPK retention
        'n': ['Medium', 'High'],
        'p': ['Medium', 'High'],
        'k': ['Medium', 'High'],
        'phMin': 5.5, 'phMax': 7.0, 'phIdeal': 6.5,
      },
      {
        'type': 'Sandy Soil',
        // Fast drainage leaches nutrients → characteristically low
        'n': ['Low'],
        'p': ['Low'],
        'k': ['Low', 'Medium'],
        'phMin': 5.5, 'phMax': 7.0, 'phIdeal': 6.0,
      },
      {
        'type': 'Silty Soil',
        // Fertile, moderate drainage → medium-to-high N, medium P & K
        'n': ['Medium', 'High'],
        'p': ['Medium'],
        'k': ['Medium'],
        'phMin': 6.0, 'phMax': 7.0, 'phIdeal': 6.5,
      },
      {
        'type': 'Loamy Soil',
        // The "ideal" type — balanced across all nutrients
        'n': ['Medium', 'High'],
        'p': ['Medium', 'High'],
        'k': ['Medium', 'High'],
        'phMin': 6.0, 'phMax': 7.0, 'phIdeal': 6.5,
      },
      {
        'type': 'Peaty Soil',
        // High organic matter → high N, but very acidic limits P & K uptake
        'n': ['High'],
        'p': ['Low', 'Medium'],
        'k': ['Low', 'Medium'],
        'phMin': 3.5, 'phMax': 6.0, 'phIdeal': 4.5,
      },
      {
        'type': 'Chalky Soil',
        // Alkaline and stony → limits micro-nutrient availability, moderate NPK
        'n': ['Low', 'Medium'],
        'p': ['Low', 'Medium'],
        'k': ['Medium'],
        'phMin': 7.5, 'phMax': 8.5, 'phIdeal': 8.0,
      },
    ];

    double bestScore = -1;
    String bestType  = 'Mixed Soil';

    for (final profile in profiles) {
      double s = 0;

      // ── NPK component (0–3 pts) ──────────────────────────────────────────
      final nMatch = (profile['n'] as List<String>).contains(n) ? 1.0 : 0.0;
      final pMatch = (profile['p'] as List<String>).contains(p) ? 1.0 : 0.0;
      final kMatch = (profile['k'] as List<String>).contains(k) ? 1.0 : 0.0;
      s += nMatch + pMatch + kMatch;

      // ── pH component (1–4 pts, continuous) ──────────────────────────────
      // We use a piecewise linear function:
      //   • pH inside [phMin, phMax]  → interpolate 1–4 based on distance
      //     to phIdeal (closer = higher score)
      //   • pH outside the tolerance  → 0 (no pH contribution)
      final phMin   = profile['phMin'] as double;
      final phMax   = profile['phMax'] as double;
      final phIdeal = profile['phIdeal'] as double;

      if (ph >= phMin && ph <= phMax) {
        final range   = (phMax - phMin) / 2.0;
        final dist    = (ph - phIdeal).abs();
        // normalised 0 (edge) → 1 (ideal)
        final closeness = range > 0 ? (1.0 - (dist / range)).clamp(0.0, 1.0) : 1.0;
        // scale to 1–4 pts so a perfect pH match is worth 4 pts
        s += 1.0 + closeness * 3.0;
      }
      // pH outside range contributes 0 — acts as a hard discriminator
      // (e.g. a pH 4.0 reading will strongly favour Peaty over Loamy even
      //  if NPK looks balanced)

      if (s > bestScore) {
        bestScore = s;
        bestType  = profile['type'] as String;
      }
    }

    return bestType;
  }

  // ── Recommendations ───────────────────────────────────────────────────────

  List<String> recommendation(String n, String p, String k) {
    final rec = <String>[];

    if (n.toLowerCase() == 'low') rec.add('Apply Nitrogen-rich fertilizer (Urea / Compost)');
    if (p.toLowerCase() == 'low') rec.add('Apply Phosphorus fertilizer (Bone meal / DAP)');
    if (k.toLowerCase() == 'low') rec.add('Apply Potassium fertilizer (Muriate of Potash)');

    if (rec.isEmpty) rec.add('Soil is well-balanced');

    return rec;
  }
}