import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});
  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  static const _faqs = [
    {'q': 'What does this app do?',
      'a': 'SoilMate measures key soil nutrients — Nitrogen (N), Phosphorus (P), Potassium (K), and pH — using color reactions captured by your smartphone camera.'},
    {'q': 'How do I use the camera to test my soil?',
      'a': 'Mix your soil sample with the provided reagents. Once the color reaction develops, tap the camera button, photograph the test strip, then tap Analyze. The app reads RGB values to estimate nutrient levels.'},
    {'q': 'What do the nutrient levels mean?',
      'a': 'Low means the soil is deficient and needs fertilization. Medium is acceptable but improvable. High means nutrients are sufficient or possibly excessive.'},
    {'q': 'What is pH and why does it matter?',
      'a': 'pH measures acidity/alkalinity on a 0–14 scale. Most plants thrive at pH 6–7. Extreme values prevent nutrient absorption even when nutrients are present.'},
    {'q': 'How accurate is the app?',
      'a': 'Accuracy depends on lighting and reagent quality. For critical agricultural decisions, cross-check with laboratory analysis.'},
    {'q': 'Can I save and compare results?',
      'a': 'Yes — tap Save after every analysis. View all past results in History and track how your soil health changes over time.'},
    {'q': 'Why does my camera result look incorrect?',
      'a': 'Use even, natural daylight. Avoid shadows and reflections. Hold the camera steady and ensure the test strip fills the frame.'},
  ];

  int? _expanded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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
                color: open ? const Color(0xFF2C5F2E).withOpacity(0.05) : cs.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: open
                        ? const Color(0xFF2C5F2E).withOpacity(0.25)
                        : cs.outline.withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(_faqs[i]['q']!,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: open ? const Color(0xFF2C5F2E) : cs.onSurface))),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: open
                            ? const Color(0xFF2C5F2E)
                            : cs.onSurface.withOpacity(0.35)),
                  ),
                ]),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_faqs[i]['a']!,
                        style: TextStyle(fontSize: 13, height: 1.6,
                            color: cs.onSurface.withOpacity(0.6))),
                  ),
                  crossFadeState: open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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