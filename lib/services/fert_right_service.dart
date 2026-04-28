import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class FertScheduleRow {
  final String stage;
  final String timing;
  final String fertilizer;
  final String formula;
  final double rateKgHa;
  final double rateForArea;
  final String notes;

  const FertScheduleRow({
    required this.stage,
    required this.timing,
    required this.fertilizer,
    required this.formula,
    required this.rateKgHa,
    required this.rateForArea,
    this.notes = '',
  });

  String get rateHaLabel  => '${rateKgHa.toStringAsFixed(1)} kg/ha';
  String get rateAreaLabel => '${rateForArea.toStringAsFixed(2)} kg';
}

class FertRightResult {
  final String crop;
  final String soilType;
  final double areaSqm;
  final String nLevel;
  final String pLevel;
  final String kLevel;
  final double ph;
  final List<FertScheduleRow> schedule;
  final bool hasPhCorrection;
  final String phCorrectionNote;
  final String dataSource;

  const FertRightResult({
    required this.crop,
    required this.soilType,
    required this.areaSqm,
    required this.nLevel,
    required this.pLevel,
    required this.kLevel,
    required this.ph,
    required this.schedule,
    this.hasPhCorrection = false,
    this.phCorrectionNote = '',
    this.dataSource = 'DA-BSWM Adaptive Balanced Fertilization Strategy (ABFS)',
  });
}

class _NPKRate {
  final double low;
  final double medium;
  final double high;

  const _NPKRate(this.low, this.medium, this.high);

  double forLevel(String level) => switch (level.toLowerCase()) {
    'low'    => low,
    'medium' => medium,
    _        => high,
  };
}

class _Stage {
  final String name;
  final String timing;
  final double nFrac; // fraction of total N applied at this stage
  final double pFrac;
  final double kFrac;
  final String notes;

  const _Stage(this.name, this.timing, this.nFrac, this.pFrac, this.kFrac,
      [this.notes = '']);
}

class _CropData {
  final _NPKRate n; // kg N element / ha
  final _NPKRate p; // kg P₂O₅ / ha
  final _NPKRate k; // kg K₂O / ha
  final List<_Stage> stages;

  const _CropData({
    required this.n,
    required this.p,
    required this.k,
    required this.stages,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// FertRightService
// Based on DA-BSWM Adaptive Balanced Fertilization Strategy
// Fertilizer grades: Urea 46-0-0, TSP 0-46-0, MOP 0-0-60
// ─────────────────────────────────────────────────────────────────────────────

class FertRightService {
  static const double _ha = 10000.0; // sqm per hectare
  static const double _ureaN = 0.46;
  static const double _tspP  = 0.46;
  static const double _mopK  = 0.60;

  static final Map<String, _CropData> _cropTable = {
    // ── Grains ────────────────────────────────────────────────────────────────
    'Rice': _CropData(
      n: const _NPKRate(90, 60, 30),
      p: const _NPKRate(60, 30, 0),
      k: const _NPKRate(60, 30, 0),
      stages: const [
        _Stage('Basal', '0 DAT (transplanting)', 1/3, 1.0, 0.5),
        _Stage('Tillering', '14–21 DAT', 1/3, 0, 0),
        _Stage('Panicle Initiation', '45–55 DAT', 1/3, 0, 0.5,
            'Stop N application after heading'),
      ],
    ),
    'Corn': _CropData(
      n: const _NPKRate(120, 90, 60),
      p: const _NPKRate(60, 30, 0),
      k: const _NPKRate(60, 30, 0),
      stages: const [
        _Stage('Basal', 'At planting', 1/3, 1.0, 1.0),
        _Stage('Sidedress 1', '30 DAS', 1/3, 0, 0),
        _Stage('Sidedress 2', '45 DAS', 1/3, 0, 0),
      ],
    ),
    // ── Solanaceous / Cucurbit vegetables ────────────────────────────────────
    'Tomato': _CropData(
      n: const _NPKRate(150, 100, 60),
      p: const _NPKRate(90, 60, 30),
      k: const _NPKRate(90, 60, 30),
      stages: const [
        _Stage('Basal', 'At transplanting', 1/3, 1.0, 0.5),
        _Stage('Top-dress 1', '2–3 WAT', 1/3, 0, 0),
        _Stage('Top-dress 2', '4–5 WAT', 1/3, 0, 0.5),
      ],
    ),
    'Eggplant': _CropData(
      n: const _NPKRate(150, 100, 60),
      p: const _NPKRate(90, 60, 30),
      k: const _NPKRate(90, 60, 30),
      stages: const [
        _Stage('Basal', 'At transplanting', 1/3, 1.0, 0.5),
        _Stage('Top-dress 1', '2–3 WAT', 1/3, 0, 0),
        _Stage('Top-dress 2', '4–5 WAT', 1/3, 0, 0.5),
      ],
    ),
    'Ampalaya': _CropData(
      n: const _NPKRate(120, 80, 50),
      p: const _NPKRate(60, 40, 20),
      k: const _NPKRate(60, 40, 20),
      stages: const [
        _Stage('Basal', 'At transplanting', 1/3, 1.0, 0.5),
        _Stage('Top-dress 1', '2–3 WAT', 1/3, 0, 0),
        _Stage('Top-dress 2', '4–5 WAT', 1/3, 0, 0.5),
      ],
    ),
    'Upo': _CropData(
      n: const _NPKRate(100, 70, 40),
      p: const _NPKRate(60, 40, 20),
      k: const _NPKRate(60, 40, 20),
      stages: const [
        _Stage('Basal', 'At transplanting', 1/3, 1.0, 0.5),
        _Stage('Top-dress 1', '2–3 WAT', 1/3, 0, 0),
        _Stage('Top-dress 2', '4–5 WAT', 1/3, 0, 0.5),
      ],
    ),
    'Watermelon': _CropData(
      n: const _NPKRate(100, 70, 40),
      p: const _NPKRate(60, 40, 20),
      k: const _NPKRate(80, 50, 25),
      stages: const [
        _Stage('Basal', 'At transplanting', 1/3, 1.0, 0.5),
        _Stage('Top-dress 1', '2–3 WAT', 1/3, 0, 0),
        _Stage('Top-dress 2', '4–5 WAT', 1/3, 0, 0.5),
      ],
    ),
    // ── Leafy vegetables ──────────────────────────────────────────────────────
    'Pechay': _CropData(
      n: const _NPKRate(90, 60, 30),
      p: const _NPKRate(60, 30, 0),
      k: const _NPKRate(30, 15, 0),
      stages: const [
        _Stage('Basal', 'At transplanting', 0.5, 1.0, 1.0),
        _Stage('Top-dress', '14–21 DAT', 0.5, 0, 0),
      ],
    ),
    'Kangkong': _CropData(
      n: const _NPKRate(90, 60, 30),
      p: const _NPKRate(60, 30, 0),
      k: const _NPKRate(30, 15, 0),
      stages: const [
        _Stage('Basal', 'At direct seeding', 0.5, 1.0, 1.0),
        _Stage('Top-dress', '14–21 DAS', 0.5, 0, 0),
      ],
    ),
    'Mustasa': _CropData(
      n: const _NPKRate(80, 50, 25),
      p: const _NPKRate(50, 25, 0),
      k: const _NPKRate(30, 15, 0),
      stages: const [
        _Stage('Basal', 'At transplanting', 0.5, 1.0, 1.0),
        _Stage('Top-dress', '14–21 DAT', 0.5, 0, 0),
      ],
    ),
    'Repolyo': _CropData(
      n: const _NPKRate(120, 80, 50),
      p: const _NPKRate(60, 40, 20),
      k: const _NPKRate(60, 40, 20),
      stages: const [
        _Stage('Basal', 'At transplanting', 1/3, 1.0, 0.5),
        _Stage('Top-dress 1', '2–3 WAT', 1/3, 0, 0),
        _Stage('Top-dress 2', '5–6 WAT', 1/3, 0, 0.5),
      ],
    ),
    // ── Legumes (nitrogen-fixing) ─────────────────────────────────────────────
    'Sitaw': _CropData(
      n: const _NPKRate(40, 20, 0),
      p: const _NPKRate(60, 40, 20),
      k: const _NPKRate(40, 20, 0),
      stages: const [
        _Stage('Basal', 'At planting', 1.0, 1.0, 1.0,
            'Legume — all fertilizer applied at once'),
      ],
    ),
    'Mungbean': _CropData(
      n: const _NPKRate(30, 15, 0),
      p: const _NPKRate(60, 40, 20),
      k: const _NPKRate(40, 20, 0),
      stages: const [
        _Stage('Basal', 'At planting', 1.0, 1.0, 1.0,
            'Nitrogen-fixing legume — minimal N needed'),
      ],
    ),
    'Peanut': _CropData(
      n: const _NPKRate(30, 15, 0),
      p: const _NPKRate(60, 40, 20),
      k: const _NPKRate(60, 40, 20),
      stages: const [
        _Stage('Basal', 'At planting', 1.0, 1.0, 1.0,
            'Nitrogen-fixing legume — minimal N needed'),
      ],
    ),
    'Soybean': _CropData(
      n: const _NPKRate(30, 20, 0),
      p: const _NPKRate(60, 40, 20),
      k: const _NPKRate(40, 20, 0),
      stages: const [
        _Stage('Basal', 'At planting', 1.0, 1.0, 1.0,
            'Nitrogen-fixing legume — minimal N needed'),
      ],
    ),
    // ── Root crops ────────────────────────────────────────────────────────────
    'Camote': _CropData(
      n: const _NPKRate(60, 30, 0),
      p: const _NPKRate(60, 30, 0),
      k: const _NPKRate(90, 60, 30),
      stages: const [
        _Stage('Basal', 'At planting', 1.0, 1.0, 0.5),
        _Stage('Top-dress', '45–60 DAS', 0, 0, 0.5),
      ],
    ),
    'Cassava': _CropData(
      n: const _NPKRate(60, 30, 0),
      p: const _NPKRate(60, 30, 0),
      k: const _NPKRate(90, 60, 30),
      stages: const [
        _Stage('Basal', 'At planting', 1.0, 1.0, 0.5),
        _Stage('Top-dress', '2–3 MAT', 0, 0, 0.5,
            '2–3 months after transplanting'),
      ],
    ),
    'Gabi': _CropData(
      n: const _NPKRate(60, 40, 20),
      p: const _NPKRate(60, 40, 20),
      k: const _NPKRate(80, 50, 25),
      stages: const [
        _Stage('Basal', 'At planting', 1.0, 1.0, 0.5),
        _Stage('Top-dress', '2–3 MAT', 0, 0, 0.5),
      ],
    ),
    // ── Alliums ───────────────────────────────────────────────────────────────
    'Sibuyas': _CropData(
      n: const _NPKRate(100, 70, 40),
      p: const _NPKRate(60, 40, 20),
      k: const _NPKRate(60, 40, 20),
      stages: const [
        _Stage('Basal', 'At transplanting', 1/3, 1.0, 0.5),
        _Stage('Top-dress 1', '3–4 WAT', 1/3, 0, 0),
        _Stage('Top-dress 2', '6–7 WAT', 1/3, 0, 0.5),
      ],
    ),
    'Bawang': _CropData(
      n: const _NPKRate(100, 70, 40),
      p: const _NPKRate(60, 40, 20),
      k: const _NPKRate(60, 40, 20),
      stages: const [
        _Stage('Basal', 'At planting', 1/3, 1.0, 0.5),
        _Stage('Top-dress 1', '3–4 WAP', 1/3, 0, 0),
        _Stage('Top-dress 2', '6–7 WAP', 1/3, 0, 0.5),
      ],
    ),
    // ── Root vegetables ───────────────────────────────────────────────────────
    'Carrot': _CropData(
      n: const _NPKRate(100, 70, 40),
      p: const _NPKRate(60, 40, 20),
      k: const _NPKRate(80, 50, 30),
      stages: const [
        _Stage('Basal', 'At direct seeding', 0.5, 1.0, 0.5),
        _Stage('Top-dress', '30–40 DAS', 0.5, 0, 0.5),
      ],
    ),
    // ── Banana ────────────────────────────────────────────────────────────────
    'Saging na Saba': _CropData(
      n: const _NPKRate(200, 150, 100),
      p: const _NPKRate(60, 40, 20),
      k: const _NPKRate(300, 200, 100),
      stages: const [
        _Stage('Basal', 'At planting', 1/3, 1.0, 1/3),
        _Stage('2nd application', '3–4 MAT', 1/3, 0, 1/3),
        _Stage('3rd application', '6–8 MAT', 1/3, 0, 1/3),
      ],
    ),
    'Pineapple': _CropData(
      n: const _NPKRate(150, 100, 60),
      p: const _NPKRate(40, 25, 10),
      k: const _NPKRate(200, 150, 100),
      stages: const [
        _Stage('Basal', 'At planting', 1/3, 1.0, 1/3),
        _Stage('2nd application', '3–4 MAT', 1/3, 0, 1/3),
        _Stage('3rd application', '6–8 MAT', 1/3, 0, 1/3),
      ],
    ),
  };

  // ── Public API ──────────────────────────────────────────────────────────────

  static List<String> get supportedCrops =>
      (_cropTable.keys.toList()..sort());

  static const List<String> soilTypes = [
    'Clay',
    'Clay Loam',
    'Loam',
    'Loamy Sand',
    'Sandy Loam',
    'Sandy Clay Loam',
    'Silty Clay',
    'Silty Loam',
    'Sandy',
    'Peaty',
  ];

  /// Compute BSWM fertilizer schedule for given soil data + crop.
  static FertRightResult getSchedule({
    required String crop,
    required String soilType,
    required String nLevel,
    required String pLevel,
    required String kLevel,
    required double ph,
    required double areaSqm,
  }) {
    final data = _cropTable[crop];
    if (data == null) {
      return FertRightResult(
        crop: crop, soilType: soilType, areaSqm: areaSqm,
        nLevel: nLevel, pLevel: pLevel, kLevel: kLevel, ph: ph,
        schedule: [],
      );
    }

    final areaFactor = areaSqm / _ha;

    // Total commercial fertilizer needed (kg) for the given area
    final totalUrea = (data.n.forLevel(nLevel) / _ureaN) * areaFactor;
    final totalTsp  = (data.p.forLevel(pLevel) / _tspP) * areaFactor;
    final totalMop  = (data.k.forLevel(kLevel) / _mopK) * areaFactor;

    // Same but per hectare (for the rate column)
    final totalUreaHa = data.n.forLevel(nLevel) / _ureaN;
    final totalTspHa  = data.p.forLevel(pLevel) / _tspP;
    final totalMopHa  = data.k.forLevel(kLevel) / _mopK;

    final List<FertScheduleRow> rows = [];

    for (final stage in data.stages) {
      if (stage.nFrac > 0 && totalUrea > 0) {
        rows.add(FertScheduleRow(
          stage: stage.name,
          timing: stage.timing,
          fertilizer: 'Urea',
          formula: '46-0-0',
          rateKgHa: totalUreaHa * stage.nFrac,
          rateForArea: totalUrea * stage.nFrac,
          notes: stage.notes,
        ));
      }
      if (stage.pFrac > 0 && totalTsp > 0) {
        rows.add(FertScheduleRow(
          stage: stage.name,
          timing: stage.timing,
          fertilizer: 'TSP',
          formula: '0-46-0',
          rateKgHa: totalTspHa * stage.pFrac,
          rateForArea: totalTsp * stage.pFrac,
          notes: stage.notes,   // propagate stage note
        ));
      }
      if (stage.kFrac > 0 && totalMop > 0) {
        rows.add(FertScheduleRow(
          stage: stage.name,
          timing: stage.timing,
          fertilizer: 'MOP',
          formula: '0-0-60',
          rateKgHa: totalMopHa * stage.kFrac,
          rateForArea: totalMop * stage.kFrac,
          notes: stage.notes,   // propagate stage note
        ));
      }
    }

    // pH correction advisory
    bool hasCorr = false;
    String corrNote = '';
    if (ph > 0) {
      if (ph < 5.0) {
        hasCorr = true;
        corrNote =
        'Soil pH ${ph.toStringAsFixed(1)} is very acidic. Apply agricultural lime '
            '(CaCO₃) at 2–4 t/ha before planting to raise pH. '
            'Wait 2–4 weeks before applying fertilizers.';
      } else if (ph < 5.5) {
        hasCorr = true;
        corrNote =
        'Soil pH ${ph.toStringAsFixed(1)} is strongly acidic. Consider liming '
            'at 1–2 t/ha if growing neutral-pH crops like corn or tomato.';
      } else if (ph > 7.5) {
        hasCorr = true;
        corrNote =
        'Soil pH ${ph.toStringAsFixed(1)} is alkaline. Micronutrient lockout '
            'may occur. Apply elemental sulfur at 0.5–2 t/ha or use acidifying '
            'fertilizers (e.g., ammonium sulfate) to lower pH.';
      }
    }

    return FertRightResult(
      crop: crop,
      soilType: soilType,
      areaSqm: areaSqm,
      nLevel: nLevel,
      pLevel: pLevel,
      kLevel: kLevel,
      ph: ph,
      schedule: rows,
      hasPhCorrection: hasCorr,
      phCorrectionNote: corrNote,
    );
  }

  // ── PDF export ──────────────────────────────────────────────────────────────

  static Future<void> exportAndSharePdf(FertRightResult result) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('MMMM d, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('SoilMate Analysis',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text('Fertilizer Recommendation Report',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
              ]),
              pw.Text(dateStr,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 12),

          // Soil data
          pw.Text('Soil Analysis',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Parameter', 'Level / Value'],
            data: [
              ['Nitrogen (N)', result.nLevel],
              ['Phosphorus (P)', result.pLevel],
              ['Potassium (K)', result.kLevel],
              ['pH', result.ph > 0 ? result.ph.toStringAsFixed(1) : 'Not set'],
              ['Soil type', result.soilType],
              ['Area', '${result.areaSqm.toStringAsFixed(0)} m²'],
            ],
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          ),
          pw.SizedBox(height: 16),

          // Crop info
          pw.Text('Crop: ${result.crop}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),

          // pH note
          if (result.hasPhCorrection) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border(left: pw.BorderSide(color: PdfColors.amber, width: 3)),
              ),
              child: pw.Text(
                'pH Advisory: ${result.phCorrectionNote}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.brown700),
              ),
            ),
            pw.SizedBox(height: 12),
          ],

          // Schedule table
          pw.Text('Fertilizer Application Schedule',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (result.schedule.isEmpty)
            pw.Text(
                'No additional fertilizer needed for the current nutrient levels.',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
          else
            pw.Table.fromTextArray(
              headers: ['Stage', 'Timing', 'Fertilizer', 'Grade', 'Rate/ha', 'Your Area'],
              data: result.schedule
                  .map((r) => [
                r.stage,
                r.timing,
                r.fertilizer,
                r.formula,
                r.rateHaLabel,
                r.rateAreaLabel,
              ])
                  .toList(),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green50),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(2.5),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1.2),
                4: pw.FlexColumnWidth(1.5),
                5: pw.FlexColumnWidth(1.5),
              },
            ),
          pw.SizedBox(height: 20),

          // Footer
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 6),
          pw.Text(
            'Data source: ${result.dataSource}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Generated by SoilMate. For advisory use only — actual rates may vary based on field conditions.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final cropSlug = result.crop.toLowerCase().replaceAll(' ', '_');
    final file = File('${dir.path}/soilmate_$cropSlug.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'SoilMate Report — ${result.crop}',
    );
  }
}