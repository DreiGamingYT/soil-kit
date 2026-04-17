// ════════════════════════════════════════════════════════════════════
//  help_guide_screen.dart  (No Google Fonts Version)
// ════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF4A6741);
const _kAmber   = Color(0xFFC4872A);
const _kBrown   = Color(0xFF8B6D47);

class HelpGuideScreen extends StatelessWidget {
  const HelpGuideScreen({super.key});

  static const _steps = [ {'icon': Icons.science_outlined, 'title': 'Prepare the sample', 'desc': 'Collect 1 tablespoon of soil. Remove stones and debris. Mix with distilled water until a thin muddy solution forms.', 'tip': 'Collect from 3–5 spots and mix for a representative sample.'}, {'icon': Icons.colorize_outlined, 'title': 'Apply the reagents', 'desc': 'Red cap → N · Blue cap → P · Yellow cap → K · White cap → pH.\nWait 2–3 minutes for the color reaction.', 'tip': 'Do one nutrient at a time to avoid contamination.'}, {'icon': Icons.camera_alt_outlined, 'title': 'Capture the color', 'desc': 'Tap the camera button. Hold your phone above the strip in even lighting. Avoid shadows and reflections.', 'tip': 'Natural daylight is best — avoid fluorescent or tinted lights.'}, {'icon': Icons.analytics_outlined, 'title': 'Analyze the result', 'desc': 'The app reads RGB values from the photo and compares them to your calibration references to estimate N, P, K, and pH.', 'tip': 'If the result seems off, retake in better lighting.'}, {'icon': Icons.save_outlined, 'title': 'Save and record', 'desc': 'Review your Overall Score and nutrient levels. Tap Save — the result appears in History for future reference.', 'tip': 'Add a note with field location, crop type, or observations.'}, {'icon': Icons.compare_arrows_outlined, 'title': 'Compare over time', 'desc': 'Visit History to compare analyses over time and track how your soil responds to weather, crops, and fertilization.', 'tip': 'Test at the start and end of each growing season.'}, ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Guide',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        itemCount: _steps.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final step = _steps[i];

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF3A322A)
                    : const Color(0xFFE2D9CC),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(step['icon'] as IconData,
                          color: _kPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step['title'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  step['desc'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step['tip'] as String,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}