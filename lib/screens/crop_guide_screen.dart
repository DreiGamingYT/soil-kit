import 'package:flutter/material.dart';
import '../main.dart';
import '../services/crop_recommendation_service.dart';
import '../services/soil_data_service.dart';
import '../models/soil_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CropGuideScreen
//
//  Two sections:
//    1. Based on Latest Scan  – auto-runs CropRecommendationService on the
//       most recent SoilResult; shows a recommended-crops row.
//    2. Browse All Crops      – searchable grid of every crop with soil needs.
// ─────────────────────────────────────────────────────────────────────────────

class CropGuideScreen extends StatefulWidget {
  // Optional: pre-fill from a scan result (e.g. navigating from CameraResult)
  final SoilResult? initialResult;
  const CropGuideScreen({super.key, this.initialResult});

  @override
  State<CropGuideScreen> createState() => _CropGuideScreenState();
}

class _CropGuideScreenState extends State<CropGuideScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Latest scan helpers ───────────────────────────────────────────────────

  SoilResult? get _latestResult {
    if (widget.initialResult != null) return widget.initialResult;
    final results = SoilDataService.instance.results;
    if (results.isEmpty) return null;
    return results.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }

  List<String> get _recommendedCrops {
    final r = _latestResult;
    if (r == null) return [];
    return CropRecommendationService.recommend(
      r.nitrogenLevel,
      r.phosphorusLevel,
      r.potassiumLevel,
      r.ph,
      r.soilType,
    );
  }

  // ── Crop catalogue ────────────────────────────────────────────────────────

  static const _crops = <_CropInfo>[
    _CropInfo('Corn',       '🌽', 'Grain',      '5.8–7.0', 'High', 'High', 'Medium', 'Loam / Sandy Loam'),
    _CropInfo('Rice',       '🌾', 'Grain',      '5.5–6.5', 'High', 'Medium', 'High', 'Clay / Silty Clay'),
    _CropInfo('Tomato',     '🍅', 'Vegetable',  '5.5–7.0', 'Medium', 'High', 'Medium', 'Loam / Sandy Loam'),
    _CropInfo('Eggplant',   '🍆', 'Vegetable',  '5.5–7.0', 'Medium', 'Medium', 'Medium', 'Loam'),
    _CropInfo('Ampalaya',   '🥒', 'Vegetable',  '5.5–6.5', 'Medium', 'Medium', 'Medium', 'Loam'),
    _CropInfo('Kangkong',   '🥬', 'Leafy Veg',  '5.5–7.0', 'High', 'Low', 'Low', 'Clay / Loam'),
    _CropInfo('Pechay',     '🥬', 'Leafy Veg',  '5.5–7.0', 'High', 'Medium', 'Low', 'Loam'),
    _CropInfo('Mustasa',    '🌿', 'Leafy Veg',  '5.5–7.0', 'High', 'Low', 'Low', 'Loam'),
    _CropInfo('Sitaw',      '🌱', 'Legume',     '5.5–6.5', 'Low', 'Medium', 'Medium', 'Sandy Loam'),
    _CropInfo('Mungbean',   '🫘', 'Legume',     '5.0–6.5', 'Low', 'Medium', 'Low', 'Loam / Sandy Loam'),
    _CropInfo('Peanut',     '🥜', 'Legume',     '5.0–6.5', 'Low', 'Medium', 'Low', 'Sandy Loam'),
    _CropInfo('Soybean',    '🫘', 'Legume',     '5.5–7.0', 'Low', 'High', 'Medium', 'Loam'),
    _CropInfo('Camote',     '🍠', 'Root Crop',  '5.0–6.5', 'Low', 'Medium', 'High', 'Sandy Loam'),
    _CropInfo('Cassava',    '🌿', 'Root Crop',  '4.5–6.5', 'Low', 'Low', 'High', 'Sandy Loam'),
    _CropInfo('Gabi',       '🌿', 'Root Crop',  '5.0–7.0', 'Low', 'Medium', 'High', 'Clay Loam'),
    _CropInfo('Carrot',     '🥕', 'Root Crop',  '5.5–7.0', 'Low', 'Medium', 'High', 'Sandy Loam / Loam'),
    _CropInfo('Sibuyas',    '🧅', 'Bulb',       '6.0–7.5', 'Medium', 'High', 'Medium', 'Loam / Sandy Loam'),
    _CropInfo('Bawang',     '🧄', 'Bulb',       '6.0–7.5', 'Medium', 'Medium', 'High', 'Loam'),
    _CropInfo('Repolyo',    '🥬', 'Vegetable',  '6.0–7.5', 'High', 'Medium', 'Medium', 'Loam'),
    _CropInfo('Upo',        '🥒', 'Vegetable',  '5.5–7.0', 'Medium', 'Medium', 'Medium', 'Loam'),
    _CropInfo('Pineapple',  '🍍', 'Fruit',      '4.5–5.5', 'Low', 'Medium', 'High', 'Sandy Loam'),
    _CropInfo('Watermelon', '🍉', 'Fruit',      '6.0–7.0', 'Medium', 'High', 'High', 'Sandy Loam'),
    _CropInfo('Saging na Saba', '🍌', 'Fruit',  '5.5–7.0', 'High', 'Medium', 'High', 'Loam / Clay Loam'),
  ];

  List<_CropInfo> get _filtered {
    if (_query.isEmpty) return _crops;
    final q = _query.toLowerCase();
    return _crops.where((c) =>
    c.name.toLowerCase().contains(q) ||
        c.category.toLowerCase().contains(q)
    ).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top    = MediaQuery.of(context).padding.top;

    return SafeArea(
      child: Column(children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(20, top > 0 ? 6 : 16, 20, 12),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Crop Guide',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
              Text('What can you grow?',
                  style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withOpacity(0.45))),
            ])),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCEBD9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.eco_rounded,
                  color: Color(0xFF3A5C38), size: 22),
            ),
          ]),
        ),

        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            // ── Based on latest scan ────────────────────────────────────────
            _buildRecommendedSection(isDark),
            const SizedBox(height: 20),

            // ── Search ──────────────────────────────────────────────────────
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search crops…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    })
                    : null,
                isDense: true,
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1C2A1A)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFD9D0C3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFD9D0C3)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Category label ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 10),
              child: Text(
                '${_filtered.length} CROPS'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Color(0xFF3A5C38),
                ),
              ),
            ),

            // ── Crop list ────────────────────────────────────────────────────
            ..._filtered.map((crop) => _CropCard(
              crop: crop,
              isRecommended: _recommendedCrops.contains(crop.name),
            )),
          ],
        )),
      ]),
    );
  }

  // ── Recommended section ───────────────────────────────────────────────────

  Widget _buildRecommendedSection(bool isDark) {
    final result = _latestResult;
    final recs   = _recommendedCrops;

    if (result == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFDCEBD9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline, color: Color(0xFF3A5C38), size: 20),
          SizedBox(width: 10),
          Expanded(child: Text(
            'Scan your soil first to get personalised crop recommendations.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF3A5C38), height: 1.4),
          )),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Scan summary badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF3A5C38),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.science_outlined, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'Based on last scan: ${result.soilType} · pH ${result.ph.toStringAsFixed(1)} · '
                'N:${result.nitrogenLevel} P:${result.phosphorusLevel} K:${result.potassiumLevel}',
            style: const TextStyle(
                color: Colors.white, fontSize: 11.5, height: 1.3),
          )),
        ]),
      ),
      const SizedBox(height: 12),

      if (recs.isEmpty)
        const Text(
          'No strong matches found — consider improving soil pH first.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        )
      else ...[
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'RECOMMENDED FOR YOUR SOIL',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Color(0xFF3A5C38),
            ),
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final crop = _crops.firstWhere(
                    (c) => c.name == recs[i],
                orElse: () => _CropInfo(recs[i], '🌿', '', '', '', '', '', ''),
              );
              return _RecommendedChip(crop: crop);
            },
          ),
        ),
      ],
    ]);
  }
}

// ── Recommended chip ──────────────────────────────────────────────────────────

class _RecommendedChip extends StatelessWidget {
  final _CropInfo crop;
  const _RecommendedChip({required this.crop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEBD9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A5C38).withOpacity(0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(crop.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            crop.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A5C38),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Crop card ─────────────────────────────────────────────────────────────────

class _CropCard extends StatelessWidget {
  final _CropInfo crop;
  final bool isRecommended;
  const _CropCard({required this.crop, required this.isRecommended});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended
              ? const Color(0xFF3A5C38).withOpacity(0.5)
              : const Color(0xFFD9D0C3),
          width: isRecommended ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        // Emoji
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: isRecommended
                ? const Color(0xFFDCEBD9)
                : const Color(0xFFF4EFE6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(crop.emoji,
              style: const TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 12),

        // Info
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(crop.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(width: 6),
              if (isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A5C38),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Best Match',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
            ]),
            const SizedBox(height: 4),
            Wrap(spacing: 6, runSpacing: 4, children: [
              _Tag('pH ${crop.ph}',       Icons.water_drop_outlined),
              _Tag('N: ${crop.nitrogen}', Icons.eco_outlined),
              _Tag('P: ${crop.phosphorus}', Icons.grain),
              _Tag('K: ${crop.potassium}', Icons.layers_outlined),
            ]),
            const SizedBox(height: 4),
            Text(crop.soilType,
                style: const TextStyle(
                    fontSize: 11, color: Colors.black45)),
          ],
        )),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Tag(this.label, this.icon);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: const Color(0xFF3A5C38)),
      const SizedBox(width: 3),
      Text(label,
          style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF3A5C38),
              fontWeight: FontWeight.w500)),
    ],
  );
}

// ── Data class ────────────────────────────────────────────────────────────────

class _CropInfo {
  final String name;
  final String emoji;
  final String category;
  final String ph;
  final String nitrogen;
  final String phosphorus;
  final String potassium;
  final String soilType;

  const _CropInfo(this.name, this.emoji, this.category, this.ph,
      this.nitrogen, this.phosphorus, this.potassium, this.soilType);
}