import 'package:flutter/material.dart';
import '../models/settings_service.dart';
import '../widgets/bottom_nav.dart';

class _Seg { final String key; final Color c; final double end;
const _Seg(this.key, this.c, this.end); }

const _nSegs = [_Seg('low',Color(0xFFEF4444),20),_Seg('caution',Color(0xFFF59E0B),30),
  _Seg('medium',Color(0xFFFF6D00),50),_Seg('caution',Color(0xFFF59E0B),55),_Seg('high',Color(0xFF22C55E),60)];
const _pSegs = [_Seg('low',Color(0xFFEF4444),10),_Seg('caution',Color(0xFFF59E0B),25),
  _Seg('medium',Color(0xFFFF6D00),40),_Seg('caution',Color(0xFFF59E0B),55),_Seg('high',Color(0xFF22C55E),70)];
const _kSegs = [_Seg('low',Color(0xFFEF4444),80),_Seg('caution',Color(0xFFF59E0B),100),
  _Seg('medium',Color(0xFFFF6D00),175),_Seg('caution',Color(0xFFF59E0B),250),_Seg('high',Color(0xFF22C55E),300)];

class ColorChartScreen extends StatelessWidget {
  const ColorChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SettingsService.instance;
    return ValueListenableBuilder<String>(
      valueListenable: s.language,
      builder: (_, __, ___) => ValueListenableBuilder<String>(
        valueListenable: s.measurementUnit,
        builder: (_, unit, __) => Scaffold(
          appBar: AppBar(title: const Text('Color Chart')),
          body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
            _ChartCard(title: 'pH Scale', unit: '', child: _PhBar()),
            const SizedBox(height: 12),
            _ChartCard(title: s.tr('nitrogen_title'), unit: unit,
                child: _NutrientBar(segs: _nSegs, s: s)),
            const SizedBox(height: 12),
            _ChartCard(title: s.tr('phosphorus_title'), unit: unit,
                child: _NutrientBar(segs: _pSegs, s: s)),
            const SizedBox(height: 12),
            _ChartCard(title: s.tr('potassium_title'), unit: unit,
                child: _NutrientBar(segs: _kSegs, s: s)),
            const SizedBox(height: 16),
            // Unit note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, size: 15,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                const SizedBox(width: 10),
                Expanded(child: Text(
                    '${s.tr('unit_note')} $unit${s.tr('unit_note2')}',
                    style: TextStyle(fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)))),
              ]),
            ),
          ]),
          bottomNavigationBar: AppBottomNav(selectedIndex: 0, onTap: (_) => Navigator.pop(context)),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title, unit; final Widget child;
  const _ChartCard({required this.title, required this.unit, required this.child});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(unit.isEmpty ? title : '$title ($unit)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: cs.onSurface.withOpacity(0.8))),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class _PhBar extends StatelessWidget {
  static const _colors = [
    Color(0xFFE53935),Color(0xFFE57C00),Color(0xFFFF9800),Color(0xFFFFB300),Color(0xFFFFEA00),
    Color(0xFF76FF03),Color(0xFF00E676),Color(0xFF00BCD4),Color(0xFF00ACC1),Color(0xFF0288D1),
    Color(0xFF1565C0),Color(0xFF4527A0),Color(0xFF6A1B9A),Color(0xFF4A148C),Color(0xFF311B92),
  ];
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      ClipRRect(borderRadius: BorderRadius.circular(8),
          child: SizedBox(height: 44, child: Row(
              children: List.generate(15, (i) => Expanded(child: Container(color: _colors[i])))))),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(15, (i) => Text('$i', style: TextStyle(
              fontSize: 9, color: cs.onSurface.withOpacity(0.45))))),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Acidic', style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
        Text('Neutral', style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
        Text('Alkaline', style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
      ]),
    ]);
  }
}

class _NutrientBar extends StatelessWidget {
  final List<_Seg> segs; final SettingsService s;
  const _NutrientBar({required this.segs, required this.s});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labels = {'low':'Low','caution':'Caution','medium':'Medium','high':'High'};
    return Column(children: [
      ClipRRect(borderRadius: BorderRadius.circular(8),
          child: SizedBox(height: 40, child: Row(
              children: segs.map((seg) => Expanded(child: Container(
                  color: seg.c, alignment: Alignment.center,
                  child: Text(labels[seg.key] ?? seg.key,
                      style: TextStyle(
                          color: seg.c == const Color(0xFFF59E0B) ? Colors.black87 : Colors.white,
                          fontSize: 9, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.clip, maxLines: 1)))).toList()))),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(s.formatValue(0), style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.4))),
        ...segs.map((seg) => Text(s.formatValue(seg.end),
            style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.4)))),
      ]),
    ]);
  }
}