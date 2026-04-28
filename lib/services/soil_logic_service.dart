class SoilLogicService {

  int phScore(double ph) {
    if (ph >= 6.0 && ph <= 7.5) return 3;
    if ((ph >= 5.5 && ph < 6.0) || (ph > 7.5 && ph <= 8.0)) return 2;
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
        'n': ['Medium', 'High'],
        'p': ['Medium', 'High'],
        'k': ['Medium', 'High'],
        'phMin': 5.5, 'phMax': 7.0, 'phIdeal': 6.5,
      },
      {
        'type': 'Sandy Soil',
        'n': ['Low'],
        'p': ['Low'],
        'k': ['Low', 'Medium'],
        'phMin': 5.5, 'phMax': 7.0, 'phIdeal': 6.0,
      },
      {
        'type': 'Silty Soil',
        'n': ['Medium', 'High'],
        'p': ['Medium'],
        'k': ['Medium'],
        'phMin': 6.0, 'phMax': 7.0, 'phIdeal': 6.5,
      },
      {
        'type': 'Loamy Soil',
        'n': ['Medium', 'High'],
        'p': ['Medium', 'High'],
        'k': ['Medium', 'High'],
        'phMin': 6.0, 'phMax': 7.0, 'phIdeal': 6.5,
      },
      {
        'type': 'Organic (High-OM) Soil',
        'n': ['High'],
        'p': ['Low', 'Medium'],
        'k': ['Low', 'Medium'],
        'phMin': 3.5, 'phMax': 6.0, 'phIdeal': 4.5,
      },
      {
        'type': 'Calcareous (Alkaline) Soil',
        'n': ['Low', 'Medium'],
        'p': ['Low', 'Medium'],
        'k': ['Medium'],
        'phMin': 7.5, 'phMax': 8.5, 'phIdeal': 8.0,
      },
    ];

    double bestScore = -1;
    String bestType  = 'Mixed/Unclassified Soil';

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

  List<String> recommendation(String n, String p, String k, {double ph = 6.5}) {
    final rec = <String>[];

    // ── pH correction (BSWM: address acidity/alkalinity before NPK) ──────────
    if (ph < 5.5) {
      rec.add('⚠️ Strongly acidic (pH ${ph.toStringAsFixed(1)}): Apply dolomite at 1–2 t/ha to correct acidity before fertilizing.');
    } else if (ph < 6.0) {
      rec.add('Slightly acidic (pH ${ph.toStringAsFixed(1)}): Apply dolomite at 0.5–1 t/ha to raise pH toward the optimal range (6.0–7.5).');
    } else if (ph > 7.5) {
      rec.add('⚠️ Alkaline soil (pH ${ph.toStringAsFixed(1)}): Avoid basic fertilizers. Apply elemental sulfur or acidifying amendments to lower pH.');
    }

    // ── NPK recommendations (BSWM fertilizer types and rates) ─────────────────
    if (n.toLowerCase() == 'low') {
      rec.add('Nitrogen LOW: Apply Urea (46-0-0) at 100–200 kg/ha, or Ammonium Sulfate (21-0-0) for acidic soils. Supplement with compost or vermicast.');
    } else if (n.toLowerCase() == 'medium') {
      rec.add('Nitrogen MEDIUM: Light Urea top-dress at 50–100 kg/ha, or maintain with organic matter.');
    }

    if (p.toLowerCase() == 'low') {
      rec.add('Phosphorus LOW: Apply TSP (0-46-0) at 100–150 kg/ha, or bone meal as an organic alternative.');
    } else if (p.toLowerCase() == 'medium') {
      rec.add('Phosphorus MEDIUM: Moderate TSP application or rock phosphate to maintain levels.');
    }

    if (k.toLowerCase() == 'low') {
      rec.add('Potassium LOW: Apply MOP (0-0-60) at 50–100 kg/ha, or wood ash as an organic source.');
    } else if (k.toLowerCase() == 'medium') {
      rec.add('Potassium MEDIUM: Light MOP or organic potassium supplementation recommended.');
    }

    if (ph >= 6.0) {
      rec.add('Zinc advisory: Apply Zinc Sulfate (ZnSO₄) at 1–2 kg/ha as basal. '
          'Zn availability decreases above pH 6.0 and deficiency is common in '
          'Philippine paddy and corn soils (BSWM ABFS recommendation).');
    }

    if (rec.isEmpty) {
      rec.add('Soil NPK and pH are well-balanced. Maintain with regular organic matter (compost or vermicast) every cropping season.');
    }

    return rec;
  }
}