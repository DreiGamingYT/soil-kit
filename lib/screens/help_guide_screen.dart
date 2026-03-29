import 'package:flutter/material.dart';

class HelpGuideScreen extends StatelessWidget {
  const HelpGuideScreen({super.key});

  static const _steps = [
    {'icon': Icons.science_outlined,      'title': 'Prepare the sample',
      'desc': 'Collect 1 tablespoon of soil. Remove stones and debris. Mix with distilled water until a thin muddy solution forms.',
      'tip': 'Collect from 3–5 spots and mix for a representative sample.'},
    {'icon': Icons.colorize_outlined,     'title': 'Apply the reagents',
      'desc': 'Red cap → N · Blue cap → P · Yellow cap → K · White cap → pH.\nWait 2–3 minutes for the color reaction.',
      'tip': 'Do one nutrient at a time to avoid contamination.'},
    {'icon': Icons.camera_alt_outlined,   'title': 'Capture the color',
      'desc': 'Tap the camera button. Hold your phone above the strip in even lighting. Avoid shadows and reflections.',
      'tip': 'Natural daylight is best — avoid fluorescent or tinted lights.'},
    {'icon': Icons.analytics_outlined,    'title': 'Analyze the result',
      'desc': 'The app reads RGB values from the photo and compares them to your calibration references to estimate N, P, K, and pH.',
      'tip': 'If the result seems off, retake in better lighting.'},
    {'icon': Icons.save_outlined,         'title': 'Save and record',
      'desc': 'Review your Overall Score and nutrient levels. Tap Save — the result appears in History for future reference.',
      'tip': 'Add a note with field location, crop type, or observations.'},
    {'icon': Icons.compare_arrows_outlined,'title': 'Compare over time',
      'desc': 'Visit History to compare analyses over time and track how your soil responds to weather, crops, and fertilization.',
      'tip': 'Test at the start and end of each growing season.'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Guide')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: _steps.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == _steps.length) return _ColorTable(cs: cs);
          final step = _steps[i];
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF2C5F2E).withOpacity(0.12))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: const Color(0xFF2C5F2E).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(step['icon'] as IconData,
                        color: const Color(0xFF2C5F2E), size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Step ${i + 1}', style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: Color(0xFF2C5F2E), letterSpacing: 0.8)),
                  Text(step['title'] as String, style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
                ])),
              ]),
              const SizedBox(height: 10),
              Text(step['desc'] as String, style: TextStyle(
                  fontSize: 13, height: 1.6, color: cs.onSurface.withOpacity(0.6))),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: Color(0xFFF59E0B), size: 14),
                  const SizedBox(width: 8),
                  Expanded(child: Text(step['tip'] as String, style: const TextStyle(
                      fontSize: 12, color: Color(0xFF7C6F00), height: 1.5))),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _ColorTable extends StatelessWidget {
  final ColorScheme cs;
  const _ColorTable({required this.cs});

  static const _rows = [
    {'n': 'Nitrogen',   'l': 'Light Yellow', 'm': 'Orange',         'h': 'Dark Red',       'c': 0xFFE53935},
    {'n': 'Phosphorus', 'l': 'Pale Blue',    'm': 'Blue',           'h': 'Dark Blue',      'c': 0xFF1565C0},
    {'n': 'Potassium',  'l': 'Light Green',  'm': 'Green',          'h': 'Dark Green',     'c': 0xFF2E7D32},
    {'n': 'pH',         'l': 'Red (Acid)',   'm': 'Green (Neutral)','h': 'Purple (Alk.)',  'c': 0xFF6A1B9A},
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.3))),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(color: Color(0xFF2C5F2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Row(children: [
          const Text('Quick Color Reference', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
      ..._rows.asMap().entries.map((e) {
        final r = e.value;
        final last = e.key == _rows.length - 1;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              border: last ? null : Border(
                  bottom: BorderSide(color: cs.outline.withOpacity(0.2)))),
          child: Row(children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: Color(r['c'] as int), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            SizedBox(width: 80, child: Text(r['n'] as String, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface))),
            Expanded(child: Text('${r['l']} · ${r['m']} · ${r['h']}',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5)))),
          ]),
        );
      }),
    ]),
  );
}