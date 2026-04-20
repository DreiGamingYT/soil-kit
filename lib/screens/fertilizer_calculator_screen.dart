import 'package:flutter/material.dart';
import '../main.dart'; // SoilColors, Sr

// ─────────────────────────────────────────────────────────────────────────────
// Fertilizer Dosage Calculator
// Input  : N / P / K level (Low/Medium/High) + area in sq metres
// Output : recommended kg per area for each fertilizer type
// ─────────────────────────────────────────────────────────────────────────────

class FertilizerCalculatorScreen extends StatefulWidget {
  /// Pre-fill levels from a soil scan result (optional)
  final String? initialN;
  final String? initialP;
  final String? initialK;

  const FertilizerCalculatorScreen({
    super.key,
    this.initialN,
    this.initialP,
    this.initialK,
  });

  @override
  State<FertilizerCalculatorScreen> createState() =>
      _FertilizerCalculatorScreenState();
}

class _FertilizerCalculatorScreenState
    extends State<FertilizerCalculatorScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  String _nLevel = 'Low';
  String _pLevel = 'Low';
  String _kLevel = 'Low';

  final _areaCtrl = TextEditingController(text: '100');
  final _levels   = ['Low', 'Medium', 'High'];

  /// Results map: fertilizer name → dosage string
  Map<String, _FertResult>? _results;

  @override
  void initState() {
    super.initState();
    _nLevel = widget.initialN ?? 'Low';
    _pLevel = widget.initialP ?? 'Low';
    _kLevel = widget.initialK ?? 'Low';
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    super.dispose();
  }

  // ── Core calculation logic ─────────────────────────────────────────────────
  //
  // Dosage table (kg/100 sqm):
  //   Urea (46-0-0)   → N supplement
  //   TSP  (0-46-0)   → P supplement
  //   MOP  (0-0-60)   → K supplement
  //   Complete (14-14-14) → balanced top-up
  //
  // Deficiency → base rate; Medium → half rate; High → skip
  void _calculate() {
    final area = double.tryParse(_areaCtrl.text.trim()) ?? 0;
    if (area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid area (> 0)'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Base rates per 100 sqm (kg)
    const ureaBase     = 2.0;   // Urea 46-0-0
    const tspBase      = 1.5;   // TSP  0-46-0
    const mopBase      = 1.5;   // MOP  0-0-60
    const completeBase = 3.0;   // 14-14-14 complete

    double factor(String level) => switch (level) {
      'Low'    => 1.0,
      'Medium' => 0.5,
      _        => 0.0,   // High → no supplement needed
    };

    final areaFactor = area / 100.0;

    final urea     = ureaBase     * factor(_nLevel) * areaFactor;
    final tsp      = tspBase      * factor(_pLevel) * areaFactor;
    final mop      = mopBase      * factor(_kLevel) * areaFactor;

    // Complete fertilizer is recommended when all three are deficient
    final allDeficient = (_nLevel != 'High') &&
        (_pLevel != 'High') &&
        (_kLevel != 'High');
    final complete = allDeficient
        ? completeBase *
        ((factor(_nLevel) + factor(_pLevel) + factor(_kLevel)) / 3) *
        areaFactor
        : 0.0;

    setState(() {
      _results = {
        'Urea (46-0-0)': _FertResult(
          kg: urea,
          purpose: 'Nitrogen boost',
          icon: '🟦',
          color: const Color(0xFF1976D2),
          skip: _nLevel == 'High',
        ),
        'TSP (0-46-0)': _FertResult(
          kg: tsp,
          purpose: 'Phosphorus boost',
          icon: '🟧',
          color: const Color(0xFFF57C00),
          skip: _pLevel == 'High',
        ),
        'MOP (0-0-60)': _FertResult(
          kg: mop,
          purpose: 'Potassium boost',
          icon: '🟪',
          color: const Color(0xFF7B1FA2),
          skip: _kLevel == 'High',
        ),
        if (allDeficient)
          'Complete (14-14-14)': _FertResult(
            kg: complete,
            purpose: 'Balanced top-up',
            icon: '🟩',
            color: SoilColors.primary,
            skip: false,
          ),
      };
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fertilizer Calculator'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info banner ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SoilColors.primaryLight
                    .withOpacity(isDark ? 0.15 : 0.45),
                borderRadius: BorderRadius.circular(Sr.rMd),
                border: Border.all(
                    color: SoilColors.primary.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enter your soil nutrient levels and plot size to get '
                          'recommended fertilizer dosages. Rates are based on '
                          'standard Philippine agricultural guidelines.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.55,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _sectionLabel('Soil Nutrient Levels'),
            const SizedBox(height: 12),

            // ── NPK selectors ──────────────────────────────────────────────
            _NutrientSelector(
              label: 'Nitrogen (N)',
              emoji: '🟦',
              value: _nLevel,
              options: _levels,
              onChanged: (v) => setState(() { _nLevel = v; _results = null; }),
            ),
            const SizedBox(height: 10),
            _NutrientSelector(
              label: 'Phosphorus (P)',
              emoji: '🟧',
              value: _pLevel,
              options: _levels,
              onChanged: (v) => setState(() { _pLevel = v; _results = null; }),
            ),
            const SizedBox(height: 10),
            _NutrientSelector(
              label: 'Potassium (K)',
              emoji: '🟪',
              value: _kLevel,
              options: _levels,
              onChanged: (v) => setState(() { _kLevel = v; _results = null; }),
            ),

            const SizedBox(height: 24),
            _sectionLabel('Plot Area'),
            const SizedBox(height: 10),

            // ── Area input ─────────────────────────────────────────────────
            TextField(
              controller: _areaCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _results = null),
              decoration: InputDecoration(
                hintText: 'e.g. 100',
                suffixText: 'sq m',
                prefixIcon: const Icon(Icons.crop_square_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Sr.rMd),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Calculate button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate_rounded, size: 18),
                label: const Text('Calculate Dosage'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SoilColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Sr.rMd),
                  ),
                ),
              ),
            ),

            // ── Results ────────────────────────────────────────────────────
            if (_results != null) ...[
              const SizedBox(height: 32),
              _sectionLabel('Recommended Dosage'),
              const SizedBox(height: 4),
              Text(
                'For ${_areaCtrl.text.trim()} sq m of land',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.45),
                ),
              ),
              const SizedBox(height: 14),
              ..._results!.entries.map(
                    (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ResultCard(name: e.key, result: e.value),
                ),
              ),

              // ── Application note ─────────────────────────────────────────
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SoilColors.harvest.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(Sr.rMd),
                  border: Border.all(
                      color: SoilColors.harvest.withOpacity(0.22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('⚠️', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 6),
                        Text(
                          'Application Tips',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _tip('Apply fertilizers in the early morning or late afternoon.'),
                    _tip('Water the soil lightly after applying granular fertilizers.'),
                    _tip('Split applications into 2–3 doses for better absorption.'),
                    _tip('Always follow local DA guidelines for your specific crop.'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  );

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nutrient level selector row ───────────────────────────────────────────────
class _NutrientSelector extends StatelessWidget {
  final String label, emoji, value;
  final List<String> options;
  final void Function(String) onChanged;

  const _NutrientSelector({
    required this.label,
    required this.emoji,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(Sr.rMd),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          // Segmented toggle
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(Sr.rSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: options.map((opt) {
                final selected = opt == value;
                Color selectedColor() => switch (opt) {
                  'Low'    => SoilColors.low,
                  'Medium' => SoilColors.medium,
                  _        => SoilColors.primary,
                };
                return GestureDetector(
                  onTap: () => onChanged(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? selectedColor()
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(Sr.rSm),
                    ),
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result card ───────────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final String name;
  final _FertResult result;

  const _ResultCard({required this.name, required this.result});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (result.skip) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(Sr.rMd),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            Text(result.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(result.purpose,
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withOpacity(0.45))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Sr.rPill),
              ),
              child: const Text(
                '✓ Not needed',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: result.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(Sr.rMd),
        border: Border.all(color: result.color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(result.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(result.purpose,
                    style: TextStyle(
                        fontSize: 11,
                        color: result.color.withOpacity(0.7))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.kg.toStringAsFixed(2)} kg',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: result.color,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                '≈ ${(result.kg * 1000).toStringAsFixed(0)} g',
                style: TextStyle(
                  fontSize: 11,
                  color: result.color.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _FertResult {
  final double kg;
  final String purpose, icon;
  final Color color;
  final bool skip;

  const _FertResult({
    required this.kg,
    required this.purpose,
    required this.icon,
    required this.color,
    required this.skip,
  });
}