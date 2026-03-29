import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/soil_result.dart';
import '../models/soil_data_service.dart';
import '../models/settings_service.dart';

class CameraResultScreen extends StatelessWidget {
  final SoilResult result;
  const CameraResultScreen({super.key, required this.result});

  Color get _scoreColor {
    if (result.overallScore >= 70) return const Color(0xFF22C55E);
    if (result.overallScore >= 45) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _levelColor(String v) {
    switch (v.toLowerCase()) {
      case 'high':   return const Color(0xFF22C55E);
      case 'medium': return const Color(0xFFF59E0B);
      default:       return const Color(0xFFEF4444);
    }
  }

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  void _showRecs(BuildContext context) {
    final s = SettingsService.instance;
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.92, minChildSize: 0.4, expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: cs.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2)))),
            Text(s.tr('recommendations'), style: TextStyle(fontSize: 20,
                fontWeight: FontWeight.w800, letterSpacing: -0.5, color: cs.onSurface)),
            const SizedBox(height: 4),
            Text('${result.soilType} · ${_months[result.date.month-1]} ${result.date.day}',
                style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.4))),
            const SizedBox(height: 20),
            if (result.nitrogenLevel == 'Low') _RecCard(
                color: const Color(0xFFEF4444), icon: Icons.grass_rounded,
                title: s.tr('nitrogen_deficiency'),
                body: 'Apply urea (46-0-0) or ammonium nitrate at 50–100 kg/ha. Consider legumes to fix nitrogen naturally.'),
            if (result.phosphorusLevel == 'Low') _RecCard(
                color: const Color(0xFFF59E0B), icon: Icons.water_drop_outlined,
                title: s.tr('phosphorus_deficiency'),
                body: 'Apply superphosphate or bone meal. Target pH 6–7 for maximum phosphorus availability.'),
            if (result.potassiumLevel == 'Low') _RecCard(
                color: const Color(0xFFD97706), icon: Icons.eco_outlined,
                title: s.tr('potassium_deficiency'),
                body: 'Apply muriate of potash (0-0-60) or wood ash. Ensure adequate soil moisture for uptake.'),
            if (result.ph < 6.0) _RecCard(
                color: const Color(0xFF8B5CF6), icon: Icons.science_outlined,
                title: '${s.tr('acidic_soil')} (pH ${result.ph})',
                body: 'Apply agricultural lime at 1–3 tonnes/ha to raise pH. Retest after 3 months.'),
            if (result.ph > 7.5) _RecCard(
                color: const Color(0xFF3B82F6), icon: Icons.science_outlined,
                title: '${s.tr('alkaline_soil')} (pH ${result.ph})',
                body: 'Apply elemental sulfur or acidifying fertilizers. Organic matter can lower pH over time.'),
            if (result.nitrogenLevel == 'High' && result.phosphorusLevel == 'High'
                && result.potassiumLevel == 'High') _RecCard(
                color: const Color(0xFF22C55E), icon: Icons.check_circle_outline_rounded,
                title: s.tr('all_good'),
                body: 'Maintain with regular organic matter. Monitor every season to prevent over-fertilization.'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: const Color(0xFFEAF3EA),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF2C5F2E), size: 16),
                SizedBox(width: 10),
                Expanded(child: Text(
                    'Retest after applying amendments (4–8 weeks). Follow local agronomist guidance.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1A3A1C), height: 1.5))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    final s = SettingsService.instance;
    SoilDataService.instance.addResult(result);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 16),
        const SizedBox(width: 8), Text(s.tr('saved')),
      ]),
      backgroundColor: const Color(0xFF2C5F2E),
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
    final dateStr = '${_months[result.date.month-1]} ${result.date.day}, ${result.date.year}';

    return ValueListenableBuilder<String>(
      valueListenable: s.language,
      builder: (_, __, ___) => ValueListenableBuilder<String>(
        valueListenable: s.measurementUnit,
        builder: (_, unit, __) => Scaffold(
          body: CustomScrollView(slivers: [
            // App bar
            SliverAppBar(
              pinned: true,
              title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(result.soilType, style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                Text(dateStr, style: TextStyle(
                    fontSize: 11, color: cs.onSurface.withOpacity(0.4),
                    fontWeight: FontWeight.w400)),
              ]),
              actions: [
                if (result.imagePath != null && File(result.imagePath!).existsSync())
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(result.imagePath!),
                          width: 36, height: 36, fit: BoxFit.cover),
                    ),
                  ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverList(delegate: SliverChildListDelegate([

                // ── Score hero card ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cs.outline.withOpacity(0.3))),
                  child: Row(children: [
                    // Donut
                    SizedBox(width: 110, height: 110,
                        child: CustomPaint(painter: _DonutPainter(result: result),
                            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Text('${result.overallScore.toInt()}%',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                                      color: _scoreColor)),
                              Text('score', style: TextStyle(fontSize: 10,
                                  color: cs.onSurface.withOpacity(0.4))),
                            ])))),
                    const SizedBox(width: 20),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: _scoreColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100)),
                        child: Text(result.status, style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: _scoreColor)),
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        _MiniDot(color: const Color(0xFFEF4444)), const SizedBox(width: 4),
                        Text('N  ', style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
                        _MiniDot(color: const Color(0xFFF59E0B)), const SizedBox(width: 4),
                        Text('P  ', style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
                        _MiniDot(color: const Color(0xFF22C55E)), const SizedBox(width: 4),
                        Text('K', style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
                      ]),
                    ])),
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Nutrient summary ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cs.outline.withOpacity(0.3))),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(s.tr('summary'), style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w700, color: cs.onSurface)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFF2C5F2E).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(unit, style: const TextStyle(
                            fontSize: 11, color: Color(0xFF2C5F2E), fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _NRow(label: s.tr('nitrogen'),   value: result.nitrogenLevel,
                        dot: const Color(0xFFEF4444), lc: _levelColor(result.nitrogenLevel)),
                    const SizedBox(height: 10),
                    _NRow(label: s.tr('phosphorus'), value: result.phosphorusLevel,
                        dot: const Color(0xFFF59E0B), lc: _levelColor(result.phosphorusLevel)),
                    const SizedBox(height: 10),
                    _NRow(label: s.tr('potassium'),  value: result.potassiumLevel,
                        dot: const Color(0xFF22C55E), lc: _levelColor(result.potassiumLevel)),
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Row(children: [
                        Container(width: 10, height: 10,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: cs.outline.withOpacity(0.4)))),
                        const SizedBox(width: 10),
                        Text('pH  ${result.ph}', style: TextStyle(
                            fontSize: 14, color: cs.onSurface.withOpacity(0.6))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(100)),
                          child: Text(result.phDescription, style: TextStyle(
                              fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
                        ),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── Actions ──────────────────────────────────────────
                SizedBox(width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showRecs(context),
                      icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                      label: Text(s.tr('view_recommendations')),
                    )),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.tr('discard')))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton.icon(
                      onPressed: () => _save(context),
                      icon: const Icon(Icons.save_alt_outlined, size: 16),
                      label: Text(s.tr('save')))),
                ]),
              ])),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MiniDot extends StatelessWidget {
  final Color color;
  const _MiniDot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _NRow extends StatelessWidget {
  final String label, value; final Color dot, lc;
  const _NRow({required this.label, required this.value, required this.dot, required this.lc});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: TextStyle(fontSize: 14,
          fontWeight: FontWeight.w500, color: cs.onSurface))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: lc.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: lc.withOpacity(0.25))),
        child: Text(value, style: TextStyle(
            color: lc, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    ]);
  }
}

class _RecCard extends StatelessWidget {
  final Color color; final IconData icon; final String title, body;
  const _RecCard({required this.color, required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
        ]),
        const SizedBox(height: 8),
        Text(body, style: TextStyle(fontSize: 13, height: 1.55,
            color: cs.onSurface.withOpacity(0.6))),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final SoilResult result;
  const _DonutPainter({required this.result});

  Color _col(String v) {
    switch (v.toLowerCase()) {
      case 'high':   return const Color(0xFF22C55E);
      case 'medium': return const Color(0xFFF59E0B);
      default:       return const Color(0xFFEF4444);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 10;
    const sw = 14.0;
    final bg = Paint()..color = Colors.grey.shade200..strokeWidth = sw..style = PaintingStyle.stroke;
    canvas.drawCircle(c, r, bg);

    final segs = [_col(result.nitrogenLevel), _col(result.phosphorusLevel), _col(result.potassiumLevel)];
    final sweep = (2 * math.pi) / 3;
    final p = Paint()..strokeWidth = sw..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      p.color = segs[i];
      canvas.drawArc(Rect.fromCircle(center: c, radius: r),
          -math.pi / 2 + i * sweep + 0.06, sweep - 0.12, false, p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}