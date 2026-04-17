import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/image_analysis_service.dart';
import '../services/calibration_service.dart';
import '../widgets/capture_box.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CalibrationScreen
//
//  Workflow:
//    Step 0 – White Reference: point at a white card / blank paper and capture.
//             This single RGB reading becomes the illuminant reference used to
//             colour-correct every subsequent calibration and analysis capture.
//
//    Step 1 – Nutrient Calibration: for each (nutrient, level) pair the user
//             captures _kSamples frames.  The screen averages them (Feature 2)
//             and stores the result alongside the white reference.
// ─────────────────────────────────────────────────────────────────────────────

enum _CalStep { whiteRef, calibrate }

class CalibrationScreen extends StatefulWidget {
  @override
  _CalibrationScreenState createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {

  // ── Camera ────────────────────────────────────────────────────────────────
  CameraController? controller;
  List<CameraDescription>? cameras;
  bool _camReady = false;

  // ── Workflow state ────────────────────────────────────────────────────────
  _CalStep _step = _CalStep.whiteRef;
  bool _whiteRefCaptured = false;

  // ── Multi-sample collection (Feature 2) ───────────────────────────────────
  static const _kSamples = 3;   // captures to average per level
  final List<List<double>> _pendingSamples = [];
  bool _capturing = false;

  // ── Nutrient selection ────────────────────────────────────────────────────
  final _nutrients = ['Nitrogen', 'Phosphorus', 'Potassium', 'pH'];
  final _levels    = ['LOW', 'MEDIUM', 'HIGH'];
  String _selectedNutrient = 'Nitrogen';
  String _selectedLevel    = 'LOW';

  // ── Saved calibration data ────────────────────────────────────────────────
  Map<String, dynamic> _calibrationData = {};

  // ── Services ──────────────────────────────────────────────────────────────
  final _imgService = ImageAnalysisService();
  final _calService = CalibrationService();

  // ── Live quality feedback ─────────────────────────────────────────────────
  // Simple brightness check so the user knows when lighting is acceptable.
  _QualityHint _qualityHint = _QualityHint.ok;

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initCam();
    _loadExisting();
  }

  Future<void> _initCam() async {
    cameras = await availableCameras();
    if (cameras == null || cameras!.isEmpty) return;
    controller = CameraController(cameras![0], ResolutionPreset.medium);
    await controller!.initialize();
    if (!mounted) return;
    setState(() => _camReady = true);
    controller!.startImageStream(_onFrame);
  }

  Future<void> _loadExisting() async {
    final existing = await _calService.loadCalibration();
    if (existing != null) setState(() => _calibrationData = Map.from(existing));
    final hasRef = await _calService.loadWhiteReference();
    if (hasRef != null && mounted) setState(() => _whiteRefCaptured = true);
  }

  void _onFrame(CameraImage frame) {
    // Lightweight brightness check from Y plane for quality feedback
    try {
      final y = frame.planes[0];
      final mid = y.bytes.length ~/ 2;
      final yVal = y.bytes[mid] & 0xFF;
      final hint = yVal < 40
          ? _QualityHint.tooDark
          : yVal > 230
          ? _QualityHint.tooBright
          : _QualityHint.ok;
      if (mounted && hint != _qualityHint) setState(() => _qualityHint = hint);
    } catch (_) {}
  }

  @override
  void dispose() {
    controller?.stopImageStream();
    controller?.dispose();
    super.dispose();
  }

  // ── White reference capture (Feature 3) ───────────────────────────────────

  Future<void> _captureWhiteRef() async {
    if (controller == null || !controller!.value.isInitialized) return;
    setState(() => _capturing = true);

    try {
      controller!.stopImageStream();
      final image = await controller!.takePicture();
      final rgb   = await _imgService.getAverageRGB(image.path);
      await _calService.saveWhiteReference(rgb);
      if (!mounted) return;
      setState(() {
        _whiteRefCaptured = true;
        _step = _CalStep.calibrate;
        _capturing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('White reference saved ✓'),
        backgroundColor: Color(0xFF3A5C38),
      ));
    } catch (e) {
      setState(() => _capturing = false);
    } finally {
      controller?.startImageStream(_onFrame);
    }
  }

  // ── Multi-sample nutrient capture (Feature 2) ──────────────────────────────

  Future<void> _captureSample() async {
    if (controller == null || !controller!.value.isInitialized) return;
    if (_capturing) return;
    setState(() => _capturing = true);

    try {
      controller!.stopImageStream();

      // Load white reference for correction
      final whiteRef = await _calService.loadWhiteReference();

      final image = await controller!.takePicture();
      final rgb   = await _imgService.getAverageRGB(
        image.path,
        whiteRef: whiteRef,
      );
      _pendingSamples.add(rgb);

      if (_pendingSamples.length >= _kSamples) {
        // Average all samples (Feature 2)
        final avg = _averageSamples(_pendingSamples);
        _pendingSamples.clear();

        _calibrationData.putIfAbsent(_selectedNutrient, () => {});
        (_calibrationData[_selectedNutrient] as Map)[_selectedLevel] = avg;

        await _calService.saveCalibration(_calibrationData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              '$_selectedNutrient · $_selectedLevel saved '
                  '(avg of $_kSamples samples) ✓',
            ),
            backgroundColor: const Color(0xFF3A5C38),
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'Sample ${_pendingSamples.length}/$_kSamples captured',
            ),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
      controller?.startImageStream(_onFrame);
    }
  }

  /// Average a list of RGB triplets into one.
  List<double> _averageSamples(List<List<double>> samples) {
    double r = 0, g = 0, b = 0;
    for (final s in samples) { r += s[0]; g += s[1]; b += s[2]; }
    final n = samples.length.toDouble();
    return [r / n, g / n, b / n];
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_camReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_step == _CalStep.whiteRef
            ? 'Step 1 — White Reference'
            : 'Step 2 — Calibrate Nutrients'),
        actions: [
          if (_step == _CalStep.calibrate)
            TextButton(
              onPressed: () => setState(() => _step = _CalStep.whiteRef),
              child: const Text('Re-capture White',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
      body: Column(children: [

        // ── Quality hint banner ────────────────────────────────────────────
        if (_qualityHint != _QualityHint.ok)
          _QualityBanner(hint: _qualityHint),

        // ── Camera preview ─────────────────────────────────────────────────
        Expanded(
          child: Stack(children: [
            CameraPreview(controller!),
            CaptureBox(),
          ]),
        ),

        // ── Controls ───────────────────────────────────────────────────────
        if (_step == _CalStep.whiteRef)
          _WhiteRefPanel(
            captured: _whiteRefCaptured,
            capturing: _capturing,
            onCapture: _captureWhiteRef,
            onSkip: () => setState(() => _step = _CalStep.calibrate),
          )
        else
          _CalibratePanel(
            nutrients: _nutrients,
            levels: _levels,
            selectedNutrient: _selectedNutrient,
            selectedLevel: _selectedLevel,
            pendingCount: _pendingSamples.length,
            totalSamples: _kSamples,
            capturing: _capturing,
            onNutrientChanged: (v) =>
                setState(() { _selectedNutrient = v; _pendingSamples.clear(); }),
            onLevelChanged: (v) =>
                setState(() { _selectedLevel = v; _pendingSamples.clear(); }),
            onCapture: _captureSample,
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Quality hint
// ─────────────────────────────────────────────────────────────────────────────

enum _QualityHint { ok, tooDark, tooBright }

class _QualityBanner extends StatelessWidget {
  final _QualityHint hint;
  const _QualityBanner({required this.hint});

  @override
  Widget build(BuildContext context) {
    final isDark = hint == _QualityHint.tooDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: isDark ? Colors.orange.shade800 : Colors.amber.shade700,
      child: Row(children: [
        Icon(isDark ? Icons.dark_mode : Icons.wb_sunny,
            color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text(
          isDark
              ? 'Too dark — move to better lighting or use torch'
              : 'Too bright — reduce light or shade the strip',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  White reference panel
// ─────────────────────────────────────────────────────────────────────────────

class _WhiteRefPanel extends StatelessWidget {
  final bool captured, capturing;
  final VoidCallback onCapture, onSkip;
  const _WhiteRefPanel({
    required this.captured,
    required this.capturing,
    required this.onCapture,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCEBD9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.wb_auto,
                color: Color(0xFF3A5C38), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('White Reference Patch',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              SizedBox(height: 2),
              Text(
                'Point at a blank white card or paper and capture once.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          )),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: capturing ? null : onSkip,
            child: Text(captured ? 'Keep existing' : 'Skip'),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(
            onPressed: capturing ? null : onCapture,
            icon: capturing
                ? const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.camera_alt, size: 18),
            label: Text(capturing ? 'Capturing…' : 'Capture White'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A5C38)),
          )),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Calibrate panel
// ─────────────────────────────────────────────────────────────────────────────

class _CalibratePanel extends StatelessWidget {
  final List<String> nutrients, levels;
  final String selectedNutrient, selectedLevel;
  final int pendingCount, totalSamples;
  final bool capturing;
  final ValueChanged<String> onNutrientChanged, onLevelChanged;
  final VoidCallback onCapture;

  const _CalibratePanel({
    required this.nutrients,
    required this.levels,
    required this.selectedNutrient,
    required this.selectedLevel,
    required this.pendingCount,
    required this.totalSamples,
    required this.capturing,
    required this.onNutrientChanged,
    required this.onLevelChanged,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Selectors
        Row(children: [
          Expanded(child: _Selector(
            label: 'Nutrient',
            value: selectedNutrient,
            items: nutrients,
            onChanged: onNutrientChanged,
          )),
          const SizedBox(width: 12),
          Expanded(child: _Selector(
            label: 'Level',
            value: selectedLevel,
            items: levels,
            onChanged: onLevelChanged,
          )),
        ]),
        const SizedBox(height: 12),

        // Progress indicator (Feature 2)
        if (pendingCount > 0) ...[
          Row(children: List.generate(totalSamples, (i) => Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < totalSamples - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < pendingCount
                    ? const Color(0xFF3A5C38)
                    : const Color(0xFFDCEBD9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ))),
          const SizedBox(height: 6),
          Text(
            'Sample $pendingCount / $totalSamples captured — keep strip in same position',
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 8),
        ] else ...[
          const SizedBox(height: 4),
          Text(
            'Capture $totalSamples samples for this level (auto-averaged)',
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 8),
        ],

        // Capture button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: capturing ? null : onCapture,
            icon: capturing
                ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.camera_alt, size: 18),
            label: Text(capturing
                ? 'Capturing…'
                : pendingCount > 0
                ? 'Capture sample ${pendingCount + 1} / $totalSamples'
                : 'Capture first sample'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A5C38),
                padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ]),
    );
  }
}

class _Selector extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const _Selector({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3A5C38),
              letterSpacing: 0.5)),
      const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((n) => DropdownMenuItem(value: n, child: Text(n)))
            .toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD9D0C3))),
        ),
      ),
    ],
  );
}