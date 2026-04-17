import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/soil_result.dart';
import '../services/soil_data_service.dart';
import '../services/settings_service.dart';
import '../main.dart';

class CameraResultScreen extends StatelessWidget {
  final SoilResult result;
  const CameraResultScreen({super.key, required this.result});

  Color get _scoreColor {
    if (result.overallScore >= 70) return SoilColors.high;
    if (result.overallScore >= 45) return SoilColors.medium;
    return SoilColors.low;
  }

  Color _levelColor(String v) {
    switch (v.toLowerCase()) {
      case 'high':   return SoilColors.high;
      case 'medium': return SoilColors.medium;
      default:       return SoilColors.low;
    }
  }

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  void _save(BuildContext context) {
    final s = SettingsService.instance;
    SoilDataService.instance.addResult(result);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text(s.tr('saved')),
      ]),
      backgroundColor: SoilColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
    Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final s = SettingsService.instance;
    final cs = Theme.of(context).colorScheme;
    final dateStr =
        '${_months[result.date.month - 1]} ${result.date.day}, ${result.date.year}';

    final hasImage = result.imagePath != null &&
        File(result.imagePath!).existsSync();

    return ValueListenableBuilder<String>(
      valueListenable: s.language,
      builder: (_, __, ___) => ValueListenableBuilder<String>(
        valueListenable: s.measurementUnit,
        builder: (_, unit, __) => Scaffold(
          body: CustomScrollView(slivers: [

            // ── App bar ─────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  result.soilType,
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface,
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.4),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ]),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
              sliver: SliverList(delegate: SliverChildListDelegate([

                // ── Captured image (top center) ─────────────────────
                if (hasImage) ...[
                  Center(
                    child: Container(
                      width: 180,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Sr.rXl),
                        border: Border.all(color: cs.outline, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Sr.rXl - 1.5),
                        child: Image.file(
                          File(result.imagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Score hero with nested donut ────────────────────
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(Sr.rXl),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Row(children: [
                    // Nested donut: outer = score, inner = NPK
                    SizedBox(
                      width: 120, height: 120,
                      child: CustomPaint(
                        painter: _NestedDonutPainter(result: result),
                        child: Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(
                              '${result.overallScore.toInt()}%',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _scoreColor,
                              ),
                            ),
                            Text(
                              'score',
                              style: TextStyle(
                                fontSize: 9,
                                color: cs.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _scoreColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(Sr.rPill),
                            border: Border.all(color: _scoreColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            result.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _scoreColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // NPK legend: outer ring (score) + inner ring (NPK)
                        Row(children: const [
                          _LegendDot(color: SoilColors.low,    label: 'N'),
                          SizedBox(width: 8),
                          _LegendDot(color: SoilColors.medium, label: 'P'),
                          SizedBox(width: 8),
                          _LegendDot(color: SoilColors.high,   label: 'K'),
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          'Inner ring = NPK',
                          style: TextStyle(
                            fontSize: 9,
                            color: cs.onSurface.withOpacity(0.35),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // pH row
                        Row(children: [
                          Icon(Icons.water_outlined,
                              size: 13, color: cs.onSurface.withOpacity(0.35)),
                          const SizedBox(width: 5),
                          Expanded(child: Text(
                            'pH ${result.ph} · ${result.phDescription}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          )),
                        ]),
                      ],
                    )),
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Nutrient summary ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(Sr.rXl),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Column(children: [
                    // Header row
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(
                        s.tr('summary'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: SoilColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 11,
                            color: SoilColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 18),

                    _NutrientRow(
                      label: s.tr('nitrogen'),
                      value: result.nitrogenLevel,
                      dotColor: SoilColors.low,
                      levelColor: _levelColor(result.nitrogenLevel),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: cs.outline.withOpacity(0.5), height: 1),
                    const SizedBox(height: 12),

                    _NutrientRow(
                      label: s.tr('phosphorus'),
                      value: result.phosphorusLevel,
                      dotColor: SoilColors.medium,
                      levelColor: _levelColor(result.phosphorusLevel),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: cs.outline.withOpacity(0.5), height: 1),
                    const SizedBox(height: 12),

                    _NutrientRow(
                      label: s.tr('potassium'),
                      value: result.potassiumLevel,
                      dotColor: SoilColors.high,
                      levelColor: _levelColor(result.potassiumLevel),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: cs.outline.withOpacity(0.5), height: 1),
                    const SizedBox(height: 12),

                    // pH row
                    Row(children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.outline),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(
                        'pH Level',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      )),
                      Text(
                        '${result.ph}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(Sr.rPill),
                        ),
                        child: Text(
                          result.phDescription,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Recommendations (inline, no button needed) ──────
                _RecommendationsSection(result: result, s: s),
                const SizedBox(height: 16),

                // ── Actions ─────────────────────────────────────────
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(s.tr('discard')),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () => _save(context),
                    icon: const Icon(Icons.save_alt_outlined, size: 16),
                    label: Text(s.tr('save')),
                  )),
                ]),
              ])),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Inline recommendations section ────────────────────────────────────────────

class _RecommendationsSection extends StatelessWidget {
  final SoilResult result;
  final SettingsService s;
  const _RecommendationsSection({required this.result, required this.s});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Section header
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 12),
        child: Row(children: [
          Container(width: 3, height: 14,
            decoration: BoxDecoration(
              color: SoilColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            s.tr('recommendations').toUpperCase(),
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              letterSpacing: 1.1, color: cs.onSurface.withOpacity(0.38),
            ),
          ),
        ]),
      ),

      if (result.nitrogenLevel == 'Low') _RecCard(
        color: SoilColors.low,
        icon: Icons.grass_rounded,
        title: s.tr('nitrogen_deficiency'),
        body: 'Apply urea (46-0-0) or ammonium nitrate at 50–100 kg/ha. Consider legumes to fix nitrogen naturally.',
      ),
      if (result.phosphorusLevel == 'Low') _RecCard(
        color: SoilColors.medium,
        icon: Icons.water_drop_outlined,
        title: s.tr('phosphorus_deficiency'),
        body: 'Apply superphosphate or bone meal. Target pH 6–7 for maximum phosphorus availability.',
      ),
      if (result.potassiumLevel == 'Low') _RecCard(
        color: SoilColors.clay,
        icon: Icons.eco_outlined,
        title: s.tr('potassium_deficiency'),
        body: 'Apply muriate of potash (0-0-60) or wood ash. Ensure adequate soil moisture for uptake.',
      ),
      if (result.ph < 6.0) _RecCard(
        color: const Color(0xFF7A5C9A),
        icon: Icons.science_outlined,
        title: '${s.tr('acidic_soil')} (pH ${result.ph})',
        body: 'Apply agricultural lime at 1–3 tonnes/ha to raise pH. Retest after 3 months.',
      ),
      if (result.ph > 7.5) _RecCard(
        color: const Color(0xFF4A7EA0),
        icon: Icons.science_outlined,
        title: '${s.tr('alkaline_soil')} (pH ${result.ph})',
        body: 'Apply elemental sulfur or acidifying fertilizers. Organic matter can lower pH over time.',
      ),
      if (result.nitrogenLevel == 'High' &&
          result.phosphorusLevel == 'High' &&
          result.potassiumLevel == 'High')
        _RecCard(
          color: SoilColors.high,
          icon: Icons.check_circle_outline_rounded,
          title: s.tr('all_good'),
          body: 'Maintain with regular organic matter. Monitor every season to prevent over-fertilization.',
        ),

      // Tip note
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SoilColors.primaryLight,
          borderRadius: BorderRadius.circular(Sr.rSm),
          border: Border.all(color: SoilColors.primary.withOpacity(0.15)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: SoilColors.primary, size: 16),
          const SizedBox(width: 10),
          const Expanded(child: Text(
            'Retest after applying amendments (4–8 weeks). Follow local agronomist guidance.',
            style: TextStyle(
              fontSize: 12, color: Color(0xFF1A3A1C), height: 1.55,
            ),
          )),
        ]),
      ),
    ]);
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
    )),
  ]);
}

class _NutrientRow extends StatelessWidget {
  final String label, value;
  final Color dotColor, levelColor;
  const _NutrientRow({
    required this.label,
    required this.value,
    required this.dotColor,
    required this.levelColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: cs.onSurface.withOpacity(0.75),
        ),
      )),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: levelColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(Sr.rPill),
          border: Border.all(color: levelColor.withOpacity(0.22)),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: levelColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ]);
  }
}

class _RecCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title, body;
  const _RecCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Sr.rMd),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: color,
            ),
          )),
        ]),
        const SizedBox(height: 10),
        Text(
          body,
          style: TextStyle(
            fontSize: 13,
            height: 1.55,
            color: cs.onSurface.withOpacity(0.6),
          ),
        ),
      ]),
    );
  }
}

// ── Nested donut painter ──────────────────────────────────────────────────────
// Outer ring = overall score arc
// Inner ring = NPK three-segment ring

class _NestedDonutPainter extends CustomPainter {
  final SoilResult result;
  const _NestedDonutPainter({required this.result});

  Color get _scoreColor {
    if (result.overallScore >= 70) return SoilColors.high;
    if (result.overallScore >= 45) return SoilColors.medium;
    return SoilColors.low;
  }

  Color _col(String v) {
    switch (v.toLowerCase()) {
      case 'high':   return SoilColors.high;
      case 'medium': return SoilColors.medium;
      default:       return SoilColors.low;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 7;
    final innerR = outerR - 22;
    const outerSW = 11.0;
    const innerSW = 9.0;
    const gap = 0.5; // small gap between inner NPK segments

    // ── Outer ring background ────────────────────────────────────────
    canvas.drawCircle(c, outerR, Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = outerSW
      ..style = PaintingStyle.stroke);

    // ── Outer ring: score arc ────────────────────────────────────────
    final scoreSweep = 2 * math.pi * (result.overallScore / 100.0);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: outerR),
      -math.pi / 2,
      scoreSweep,
      false,
      Paint()
        ..color = _scoreColor
        ..strokeWidth = outerSW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // ── Inner ring background ────────────────────────────────────────
    canvas.drawCircle(c, innerR, Paint()
      ..color = const Color(0xFFE8DDD0)
      ..strokeWidth = innerSW
      ..style = PaintingStyle.stroke);

    // ── Inner ring: NPK three segments ───────────────────────────────
    final segs = [
      _col(result.nitrogenLevel),
      _col(result.phosphorusLevel),
      _col(result.potassiumLevel),
    ];
    final sweep = (2 * math.pi) / 3;
    final segPaint = Paint()
      ..strokeWidth = innerSW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      segPaint.color = segs[i];
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: innerR),
        -math.pi / 2 + i * sweep + gap,
        sweep - gap * 2,
        false,
        segPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}