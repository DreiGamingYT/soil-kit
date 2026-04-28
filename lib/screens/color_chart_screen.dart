import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../main.dart';
import '../widgets/bottom_nav.dart';

class _Seg {
  final String key;
  final Color c;
  final double end;
  const _Seg(this.key, this.c, this.end);
}

const _nSegs = [
  _Seg('low', Color(0xFFB84B38), 20),
  _Seg('caution', Color(0xFFBF903E), 30),
  _Seg('medium', Color(0xFFC4934A), 50),
  _Seg('caution', Color(0xFFBF903E), 55),
  _Seg('high', Color(0xFF4A8A46), 60),
];
const _pSegs = [
  _Seg('low', Color(0xFFB84B38), 10),
  _Seg('caution', Color(0xFFBF903E), 25),
  _Seg('medium', Color(0xFFC4934A), 40),
  _Seg('caution', Color(0xFFBF903E), 55),
  _Seg('high', Color(0xFF4A8A46), 70),
];
const _kSegs = [
  _Seg('low', Color(0xFFB84B38), 80),
  _Seg('caution', Color(0xFFBF903E), 100),
  _Seg('medium', Color(0xFFC4934A), 175),
  _Seg('caution', Color(0xFFBF903E), 250),
  _Seg('high', Color(0xFF4A8A46), 300),
];

class ColorChartScreen extends StatelessWidget {
  final bool showBottomNav;

  const ColorChartScreen({
    super.key,
    this.showBottomNav = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = SettingsService.instance;
    return ValueListenableBuilder<String>(
      valueListenable: s.language,
      builder: (_, __, ___) => ValueListenableBuilder<String>(
        valueListenable: s.measurementUnit,
        builder: (_, unit, __) => Scaffold(
          appBar: AppBar(title: const Text('Color Chart')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
            children: [
              _ChartCard(
                title: 'pH Scale',
                unit: '',
                child: _PhBar(),
              ),
              const SizedBox(height: 12),
              _ChartCard(
                title: s.tr('nitrogen_title'),
                unit: unit,
                child: _NutrientBar(segs: _nSegs, s: s),
              ),
              const SizedBox(height: 12),
              _ChartCard(
                title: s.tr('phosphorus_title'),
                unit: unit,
                child: _NutrientBar(segs: _pSegs, s: s),
              ),
              const SizedBox(height: 12),
              _ChartCard(
                title: s.tr('potassium_title'),
                unit: unit,
                child: _NutrientBar(segs: _kSegs, s: s),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SoilColors.primaryLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(Sr.rSm),
                  border: Border.all(
                    color: SoilColors.primary.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: SoilColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${s.tr('unit_note')} $unit${s.tr('unit_note2')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: SoilColors.primary.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: showBottomNav
              ? AppBottomNav(
            selectedIndex: 1,
            onTap: (_) => Navigator.pop(context),
          )
              : null,
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title, unit;
  final Widget child;
  const _ChartCard({
    required this.title,
    required this.unit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Sr.rLg),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: SoilColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit.isEmpty ? title : '$title ($unit)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withOpacity(0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PhBar extends StatelessWidget {
  static const _colors = [
    Color(0xFFD94032),
    Color(0xFFD96A2E),
    Color(0xFFE08730),
    Color(0xFFD4A827),
    Color(0xFFC8C832),
    Color(0xFF8ABF2E),
    Color(0xFF4AAF3A),
    Color(0xFF2EA875),
    Color(0xFF2898C0),
    Color(0xFF2278B8),
    Color(0xFF1A5CA8),
    Color(0xFF3844A0),
    Color(0xFF5534A0),
    Color(0xFF6B2898),
    Color(0xFF4A1890),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 44,
            child: Row(
              children: List.generate(
                15,
                    (i) => Expanded(child: Container(color: _colors[i])),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            15,
                (i) => Text(
              '$i',
              style: TextStyle(fontSize: 9, color: cs.onSurface.withOpacity(0.4)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Acidic', style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.45))),
            Text('Neutral', style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.45))),
            Text('Alkaline', style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.45))),
          ],
        ),
      ],
    );
  }
}

class _NutrientBar extends StatelessWidget {
  final List<_Seg> segs;
  final SettingsService s;
  const _NutrientBar({required this.segs, required this.s});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const labels = {
      'low': 'Low',
      'caution': 'Caution',
      'medium': 'Medium',
      'high': 'High',
    };

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 40,
            child: Row(
              children: segs
                  .map(
                    (seg) => Expanded(
                  child: Container(
                    color: seg.c,
                    alignment: Alignment.center,
                    child: Text(
                      labels[seg.key] ?? seg.key,
                      style: TextStyle(
                        color: seg.key == 'caution' ? Colors.black87 : Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.formatValue(0),
              style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.38)),
            ),
            ...segs.map(
                  (seg) => Text(
                s.formatValue(seg.end),
                style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.38)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}