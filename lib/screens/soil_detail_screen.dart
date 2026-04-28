import 'package:flutter/material.dart';

class SoilDetailScreen extends StatelessWidget {
  final Map<String, dynamic> soil;
  const SoilDetailScreen({super.key, required this.soil});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final soilColor = Color(soil['color'] as int);
    final isLight = (soil['color'] as int) == 0xFFECEFF1 || (soil['color'] as int) == 0xFFD7CCC8;

    return Scaffold(
      body: CustomScrollView(slivers: [
        // Hero app bar
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: soilColor,
          iconTheme: IconThemeData(color: isLight ? Colors.black87 : Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(soil['name'] as String,
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5,
                    color: isLight ? Colors.black87 : Colors.white)),
            background: Container(
              color: soilColor,
              child: Center(child: Icon(Icons.landscape_rounded, size: 64,
                  color: (isLight ? Colors.brown : Colors.white).withOpacity(0.2))),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(delegate: SliverChildListDelegate([
            _InfoTile(label: 'Description', value: soil['fullDesc'] as String, cs: cs),
            const SizedBox(height: 10),
            _InfoTile(label: 'Best Crops', value: soil['crops'] as String, cs: cs),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _InfoTile(label: 'pH Range',
                  value: soil['ph'] as String, cs: cs)),
              const SizedBox(width: 10),
              Expanded(child: _InfoTile(label: 'Drainage',
                  value: soil['drainage'] as String, cs: cs)),
            ]),
            const SizedBox(height: 10),
            // Tips card with amber accent
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.25)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: const [
                  Icon(Icons.lightbulb_outline_rounded,
                      color: Color(0xFFF59E0B), size: 16),
                  SizedBox(width: 8),
                  Text('Improvement Tips', style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B), letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 8),
                Text(soil['tips'] as String,
                    style: const TextStyle(fontSize: 13, height: 1.6,
                        color: Color(0xFF7C6F00))),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Test This Soil'),
              ),
            ),
            const SizedBox(height: 8),
          ])),
        ),
      ]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  final ColorScheme cs;
  const _InfoTile({required this.label, required this.value, required this.cs});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.3))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: Color(0xFF2C5F2E), letterSpacing: 0.8)),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 13, height: 1.5,
          color: cs.onSurface.withOpacity(0.8))),
    ]),
  );
}