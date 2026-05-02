import 'package:flutter/material.dart';
import '../main.dart';
import '../services/fert_right_service.dart';

class FertRightScreen extends StatefulWidget {
  final String? initialN;
  final String? initialP;
  final String? initialK;
  final double? initialPh;
  final String? initialSoilType;

  const FertRightScreen({
    super.key,
    this.initialN,
    this.initialP,
    this.initialK,
    this.initialPh,
    this.initialSoilType,
  });

  @override
  State<FertRightScreen> createState() => _FertRightScreenState();
}

class _FertRightScreenState extends State<FertRightScreen> {
  // ── Soil data state ────────────────────────────────────────────────────────
  late String _nLevel;
  late String _pLevel;
  late String _kLevel;
  late double _ph;
  bool _useLabOverride = false;

  // Lab input controllers
  final _phCtrl   = TextEditingController();

  // Crop & site
  String _crop     = 'Rice';
  String _soilType = 'Loam';
  final _areaCtrl  = TextEditingController(text: '1000');

  // Result
  FertRightResult? _result;
  bool _exporting = false;

  static const List<String> _levels = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _nLevel   = _normalise(widget.initialN) ?? 'Low';
    _pLevel   = _normalise(widget.initialP) ?? 'Low';
    _kLevel   = _normalise(widget.initialK) ?? 'Low';
    _ph       = widget.initialPh ?? 0;
    _soilType = _normaliseSoilType(widget.initialSoilType) ?? 'Loam';
    _phCtrl.text = _ph > 0 ? _ph.toStringAsFixed(1) : '';

    // If data came from a scan, show it immediately but allow lab override
    if (widget.initialN != null) {
      _useLabOverride = false;
    }
  }

  @override
  void dispose() {
    _phCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  String? _normalise(String? raw) {
    if (raw == null) return null;
    final lower = raw.toLowerCase();
    if (lower == 'high')   return 'High';
    if (lower == 'medium') return 'Medium';
    if (lower == 'low')    return 'Low';
    return null;
  }

  String? _normaliseSoilType(String? raw) {
    if (raw == null) return null;
    final lower = raw.toLowerCase();

    // Exact match first — already a valid soilTypes value
    if (FertRightService.soilTypes.contains(raw)) return raw;

    // Map inferSoilType() outputs → nearest FertRightService.soilTypes value
    if (lower.contains('peaty'))  return 'Peaty';
    if (lower.contains('sandy'))  return 'Sandy';
    if (lower.contains('silty'))  return 'Silty Loam';
    if (lower.contains('clay'))   return 'Clay';
    if (lower.contains('loam'))   return 'Loam';

    // Chalky / Mixed / anything unknown → default
    return 'Loam';
  }

  bool get _hasPrefilledData => widget.initialN != null;

  void _generate() {
    final area = double.tryParse(_areaCtrl.text.trim()) ?? 0;
    if (area <= 0) {
      _snack('Please enter a valid area (> 0 m²).');
      return;
    }
    setState(() {
      _result = FertRightService.getSchedule(
        crop: _crop,
        soilType: _soilType,
        nLevel: _nLevel,
        pLevel: _pLevel,
        kLevel: _kLevel,
        ph: _ph,
        areaSqm: area,
      );
    });
  }

  Future<void> _export() async {
    if (_result == null) return;
    setState(() => _exporting = true);
    try {
      await FertRightService.exportAndSharePdf(_result!);
    } catch (e) {
      if (mounted) _snack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fertilizer Schedule'),
        actions: [
          if (_result != null)
            _exporting
                ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Export PDF',
              onPressed: _export,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // BSWM badge
            _BswmBadge(),
            const SizedBox(height: 16),

            // ── Section 1: Soil data ────────────────────────────────────────
            _sectionHeader('Soil Data', Icons.science_outlined),
            const SizedBox(height: 10),

            if (_hasPrefilledData)
              _SourceToggle(
                useLab: _useLabOverride,
                onChanged: (v) => setState(() => _useLabOverride = v),
              ),
            if (_hasPrefilledData) const SizedBox(height: 10),

            // NPK level pickers
            _NpkRow(
              label: 'Nitrogen (N)',
              value: _nLevel,
              editable: _useLabOverride || !_hasPrefilledData,
              onChanged: (v) => setState(() { _nLevel = v; _result = null; }),
            ),
            const SizedBox(height: 8),
            _NpkRow(
              label: 'Phosphorus (P)',
              value: _pLevel,
              editable: _useLabOverride || !_hasPrefilledData,
              onChanged: (v) => setState(() { _pLevel = v; _result = null; }),
            ),
            const SizedBox(height: 8),
            _NpkRow(
              label: 'Potassium (K)',
              value: _kLevel,
              editable: _useLabOverride || !_hasPrefilledData,
              onChanged: (v) => setState(() { _kLevel = v; _result = null; }),
            ),
            const SizedBox(height: 8),

            // pH input
            _PhInput(
              controller: _phCtrl,
              editable: _useLabOverride || !_hasPrefilledData || _ph == 0,
              onChanged: (v) {
                final parsed = double.tryParse(v);
                setState(() {
                  _ph = parsed ?? 0;
                  _result = null;
                });
              },
            ),

            const SizedBox(height: 20),

            // ── Section 2: Crop & site ──────────────────────────────────────
            _sectionHeader('Crop & Site', Icons.grass_rounded),
            const SizedBox(height: 10),

            // Crop dropdown
            _DropdownField(
              label: 'Crop',
              value: _crop,
              items: FertRightService.supportedCrops,
              onChanged: (v) => setState(() { _crop = v!; _result = null; }),
            ),
            const SizedBox(height: 8),

            // Soil type dropdown
            _DropdownField(
              label: 'Soil type',
              value: _soilType,
              items: FertRightService.soilTypes,
              onChanged: (v) => setState(() { _soilType = v!; _result = null; }),
            ),
            const SizedBox(height: 8),

            // Area input
            TextField(
              controller: _areaCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _result = null),
              decoration: const InputDecoration(
                labelText: 'Field area',
                suffixText: 'm²',
                hintText: 'e.g. 1000',
                prefixIcon: Icon(Icons.crop_free_rounded),
              ),
            ),

            const SizedBox(height: 20),

            // Generate button
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Generate Fertilizer Schedule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SoilColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _generate,
            ),

            // ── Section 3: Schedule ─────────────────────────────────────────
            if (_result != null) ...[
              const SizedBox(height: 28),
              _sectionHeader('Fertilizer Schedule', Icons.calendar_month_outlined),
              const SizedBox(height: 4),
              _GovBadge(),
              const SizedBox(height: 12),

              // pH advisory
              if (_result!.hasPhCorrection)
                _PhAdvisoryCard(note: _result!.phCorrectionNote),

              // Schedule table or empty state
              if (_result!.schedule.isEmpty)
                _EmptyScheduleCard(nLevel: _nLevel, pLevel: _pLevel, kLevel: _kLevel)
              else
                _ScheduleTable(rows: _result!.schedule, areaSqm: _result!.areaSqm),

              const SizedBox(height: 16),
              _DisclaimerText(),

              const SizedBox(height: 16),

              // PDF export button
              OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: _exporting
                    ? const Text('Exporting…')
                    : const Text('Export as PDF'),
                onPressed: _exporting ? null : _export,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Icon(icon, size: 18, color: SoilColors.primary),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BswmBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(Sr.rMd),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(children: [
        const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Powered by DA-BSWM Adaptive Balanced Fertilization Strategy',
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }
}

class _GovBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _pill('DA-BSWM validated'),
        _pill('Philippine crops'),
      ],
    );
  }

  Widget _pill(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32))),
  );
}

class _SourceToggle extends StatelessWidget {
  final bool useLab;
  final ValueChanged<bool> onChanged;

  const _SourceToggle({required this.useLab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(Sr.rMd),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              useLab ? 'Lab input mode' : 'Using scan results',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              useLab
                  ? 'Enter soil lab test values to override scan data'
                  : 'Tap to enter official lab results instead',
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)),
            ),
          ]),
        ),
        Switch(
          value: useLab,
          activeColor: SoilColors.primary,
          onChanged: onChanged,
        ),
      ]),
    );
  }
}

class _NpkRow extends StatelessWidget {
  final String label;
  final String value;
  final bool editable;
  final ValueChanged<String> onChanged;

  const _NpkRow({
    required this.label,
    required this.value,
    required this.editable,
    required this.onChanged,
  });

  static const _levels = ['Low', 'Medium', 'High'];

  Color _chipColor(String level, bool selected) {
    if (!selected) return Colors.transparent;
    return switch (level) {
      'High'   => const Color(0xFF2E7D32),
      'Medium' => const Color(0xFFE65100),
      _        => const Color(0xFFC62828),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 130,
        child: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ),
      Expanded(
        child: editable
            ? Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: _levels.map((lvl) {
            final selected = value == lvl;
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () => onChanged(lvl),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? _chipColor(lvl, true).withOpacity(0.12)
                        : Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.4),
                    border: Border.all(
                      color: selected
                          ? _chipColor(lvl, true)
                          : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    lvl,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? _chipColor(lvl, true)
                          : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        )
            : Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _chipColor(value, true).withOpacity(0.12),
              border:
              Border.all(color: _chipColor(value, true)),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _chipColor(value, true))),
          ),
        ),
      ),
    ]);
  }
}

class _PhInput extends StatelessWidget {
  final TextEditingController controller;
  final bool editable;
  final ValueChanged<String> onChanged;

  const _PhInput({
    required this.controller,
    required this.editable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const SizedBox(
        width: 130,
        child: Text('Soil pH',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ),
      Expanded(
        child: TextField(
          controller: controller,
          enabled: editable,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: editable ? 'e.g. 6.5' : '—',
            isDense: true,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Sr.rMd),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Sr.rMd),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: label == 'Crop'
            ? const Icon(Icons.eco_outlined)
            : const Icon(Icons.layers_outlined),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ScheduleTable extends StatelessWidget {
  final List<FertScheduleRow> rows;
  final double areaSqm;

  const _ScheduleTable({required this.rows, required this.areaSqm});

  @override
  Widget build(BuildContext context) {
    // Group rows by stage name for visual separation
    final stages = rows.map((r) => r.stage).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: stages.map((stage) {
        final stageRows = rows.where((r) => r.stage == stage).toList();
        final timing = stageRows.first.timing;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(Sr.rMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stage header
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: SoilColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(Sr.rMd),
                    topRight: Radius.circular(Sr.rMd),
                  ),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(stage,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: SoilColors.primary)),
                      Row(children: [
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: SoilColors.primary),
                        const SizedBox(width: 4),
                        Text(timing,
                            style: const TextStyle(
                                fontSize: 11, color: SoilColors.primary)),
                      ]),
                    ]),
              ),

              // Column headers
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(children: [
                  Expanded(
                      flex: 5,
                      child: _headerText('Fertilizer')),
                  Expanded(
                      flex: 3,
                      child: _headerText('Grade', center: true)),
                  Expanded(
                      flex: 4,
                      child: _headerText('Rate/ha', center: true)),
                  Expanded(
                      flex: 4,
                      child: _headerText('For ${areaSqm.toStringAsFixed(0)} m²',
                          center: true)),
                ]),
              ),
              Divider(
                  height: 1,
                  color:
                  Theme.of(context).colorScheme.outline.withOpacity(0.2)),

              // Data rows
              ...stageRows.map((row) {
                return Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(
                          flex: 5,
                          child: Text(row.fertilizer,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(row.formula,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace')),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(row.rateHaLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12)),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(row.rateAreaLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: SoilColors.primary)),
                        ),
                      ]),
                      if (row.notes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('• ${row.notes}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5))),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _headerText(String text, {bool center = false}) => Text(
    text,
    textAlign: center ? TextAlign.center : TextAlign.start,
    style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600),
  );
}

class _PhAdvisoryCard extends StatelessWidget {
  final String note;

  const _PhAdvisoryCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: const Border(
            left: BorderSide(color: Color(0xFFFFA000), width: 3)),
        borderRadius: BorderRadius.circular(Sr.rMd),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFF57F17), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            note,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4E342E),
                height: 1.5),
          ),
        ),
      ]),
    );
  }
}

class _EmptyScheduleCard extends StatelessWidget {
  final String nLevel;
  final String pLevel;
  final String kLevel;

  const _EmptyScheduleCard(
      {required this.nLevel, required this.pLevel, required this.kLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(Sr.rMd),
      ),
      child: Column(children: [
        const Icon(Icons.check_circle_outline_rounded,
            color: Color(0xFF2E7D32), size: 32),
        const SizedBox(height: 8),
        const Text('No fertilizer needed',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B5E20))),
        const SizedBox(height: 4),
        Text(
          'Your soil has High levels of all major nutrients '
              '(N: $nLevel, P: $pLevel, K: $kLevel). '
              'Maintain soil health with organic matter.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xFF388E3C)),
        ),
      ]),
    );
  }
}

class _DisclaimerText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Based on DA-BSWM Adaptive Balanced Fertilization Strategy. '
          'Rates are indicative — adjust based on actual field conditions and '
          'soil lab confirmation.',
      style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
          height: 1.5),
    );
  }
}