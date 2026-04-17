// ══════════════════════════════════════════════════════════════════════════════
// faq_screen.dart
// ══════════════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../main.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});
  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  static const _faqs = [
    {
      'q': 'What does this app do?',
      'a': 'SoilMate measures key soil nutrients — Nitrogen (N), Phosphorus (P), Potassium (K), and pH — using color reactions captured by your smartphone camera.',
    },
    {
      'q': 'How do I use the camera to test my soil?',
      'a': 'Mix your soil sample with the provided reagents. Once the color reaction develops, tap the camera button, photograph the test strip, then tap Analyze. The app reads RGB values to estimate nutrient levels.',
    },
    {
      'q': 'What do the nutrient levels mean?',
      'a': 'Low means the soil is deficient and needs fertilization. Medium is acceptable but improvable. High means nutrients are sufficient or possibly excessive.',
    },
    {
      'q': 'What is pH and why does it matter?',
      'a': 'pH measures acidity/alkalinity on a 0–14 scale. Most plants thrive at pH 6–7. Extreme values prevent nutrient absorption even when nutrients are present.',
    },
    {
      'q': 'How accurate is the app?',
      'a': 'Accuracy depends on lighting and reagent quality. For critical agricultural decisions, cross-check with laboratory analysis.',
    },
    {
      'q': 'Can I save and compare results?',
      'a': 'Yes — tap Save after every analysis. View all past results in History and track how your soil health changes over time.',
    },
    {
      'q': 'Why does my camera result look incorrect?',
      'a': 'Use even, natural daylight. Avoid shadows and reflections. Hold the camera steady and ensure the test strip fills the frame.',
    },
  ];

  int? _expanded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        itemCount: _faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final open = _expanded == i;
          return GestureDetector(
            onTap: () => setState(() => _expanded = open ? null : i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: open ? SoilColors.primaryLight.withOpacity(0.4) : cs.surface,
                borderRadius: BorderRadius.circular(Sr.rMd),
                border: Border.all(
                  color: open
                      ? SoilColors.primary.withOpacity(0.28)
                      : cs.outline,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  // Number badge
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: open ? SoilColors.primary : cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: open ? Colors.white : cs.onSurface.withOpacity(0.45),
                      ),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    _faqs[i]['q']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: open ? SoilColors.primary : cs.onSurface,
                    ),
                  )),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: open
                          ? SoilColors.primary
                          : cs.onSurface.withOpacity(0.32),
                    ),
                  ),
                ]),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14, left: 34),
                    child: Text(
                      _faqs[i]['a']!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.65,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                  crossFadeState: open
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════════════════════
// help_guide_screen.dart
// ══════════════════════════════════════════════════════════════════════════════

class HelpGuideScreen extends StatelessWidget {
  const HelpGuideScreen({super.key});

  static const _steps = [
    {
      'icon': Icons.science_outlined,
      'title': 'Prepare the sample',
      'desc': 'Collect 1 tablespoon of soil. Remove stones and debris. Mix with distilled water until a thin muddy solution forms.',
      'tip': 'Collect from 3–5 spots and mix for a representative sample.',
    },
    {
      'icon': Icons.colorize_outlined,
      'title': 'Apply the reagents',
      'desc': 'Red cap → N · Blue cap → P · Yellow cap → K · White cap → pH.\nWait 2–3 minutes for the color reaction.',
      'tip': 'Do one nutrient at a time to avoid contamination.',
    },
    {
      'icon': Icons.camera_alt_outlined,
      'title': 'Capture the color',
      'desc': 'Tap the camera button. Hold your phone above the strip in even lighting. Avoid shadows and reflections.',
      'tip': 'Natural daylight is best — avoid fluorescent or tinted lights.',
    },
    {
      'icon': Icons.analytics_outlined,
      'title': 'Analyze the result',
      'desc': 'The app reads RGB values from the photo and compares them to your calibration references to estimate N, P, K, and pH.',
      'tip': 'If the result seems off, retake in better lighting.',
    },
    {
      'icon': Icons.save_outlined,
      'title': 'Save and record',
      'desc': 'Review your Overall Score and nutrient levels. Tap Save — the result appears in History for future reference.',
      'tip': 'Add a note with field location, crop type, or observations.',
    },
    {
      'icon': Icons.compare_arrows_outlined,
      'title': 'Compare over time',
      'desc': 'Visit History to compare analyses over time and track how your soil responds to weather, crops, and fertilization.',
      'tip': 'Test at the start and end of each growing season.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Guide')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        itemCount: _steps.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == _steps.length) return _ColorTable(cs: cs);
          final step = _steps[i];
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(Sr.rLg),
              border: Border.all(color: cs.outline),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: SoilColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(step['icon'] as IconData,
                      color: SoilColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${i + 1}',
                      style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: SoilColors.primary, letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      step['title'] as String,
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                )),
              ]),
              const SizedBox(height: 12),
              Text(
                step['desc'] as String,
                style: TextStyle(
                  fontSize: 13, height: 1.65,
                  color: cs.onSurface.withOpacity(0.58),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8),
                  borderRadius: BorderRadius.circular(Sr.rSm),
                  border: Border.all(
                    color: SoilColors.harvest.withOpacity(0.25),
                  ),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: SoilColors.harvest, size: 14),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    step['tip'] as String,
                    style: const TextStyle(
                      fontSize: 12, color: Color(0xFF7C6000), height: 1.5,
                    ),
                  )),
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
    {'n': 'Nitrogen',   'l': 'Light Yellow', 'm': 'Orange',          'h': 'Dark Red',      'c': 0xFFB84B38},
    {'n': 'Phosphorus', 'l': 'Pale Blue',    'm': 'Blue',            'h': 'Dark Blue',     'c': 0xFF1565C0},
    {'n': 'Potassium',  'l': 'Light Green',  'm': 'Green',           'h': 'Dark Green',    'c': 0xFF3A5C38},
    {'n': 'pH',         'l': 'Red (Acid)',   'm': 'Green (Neutral)', 'h': 'Purple (Alk.)', 'c': 0xFF6A1B9A},
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(Sr.rLg),
      border: Border.all(color: cs.outline),
    ),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          color: SoilColors.primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(Sr.rLg)),
        ),
        child: Row(children: const [
          Icon(Icons.palette_outlined, color: Colors.white, size: 15),
          SizedBox(width: 8),
          Text(
            'Quick Color Reference',
            style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13,
            ),
          ),
        ]),
      ),
      ..._rows.asMap().entries.map((e) {
        final r = e.value;
        final last = e.key == _rows.length - 1;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(bottom: BorderSide(color: cs.outline.withOpacity(0.6))),
          ),
          child: Row(children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: Color(r['c'] as int),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(width: 82, child: Text(r['n'] as String, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface,
            ))),
            Expanded(child: Text(
              '${r['l']} · ${r['m']} · ${r['h']}',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.45)),
            )),
          ]),
        );
      }),
    ]),
  );
}