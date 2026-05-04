import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/soil_result.dart';
import '../services/calibration_service.dart';
import '../services/image_analysis_service.dart';
import '../services/soil_logic_service.dart';
import 'camera_result_screen.dart';
import 'calibration_screen.dart';

enum _DetectState { scanning, soilFound, noSoil }

enum _QualityIssue { none, tooDark, tooBright, blurry }

class CameraScreen extends StatefulWidget {
  final String? initialImagePath;
  final SoilTestType? testType;
  const CameraScreen({super.key, this.initialImagePath, this.testType});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {

  // ── Camera ────────────────────────────────────────────────────────────────
  CameraController? _ctrl;
  List<CameraDescription> _cameras = [];
  bool _camReady = false;
  bool _camError = false;
  String _errorMsg = '';
  bool _torchOn = false;

  // ── Soil detection ────────────────────────────────────────────────────────
  _DetectState _detectState = _DetectState.scanning;
  double _soilConfidence = 0.0;
  int _frameCount = 0;
  static const int _kSampleEvery = 20;
  bool _streamProcessing = false;

  // ── Live quality feedback (Feature 5) ─────────────────────────────────────
  _QualityIssue _qualityIssue  = _QualityIssue.none;
  double        _brightness    = 0.5;   // 0–1 normalised Y average
  double        _frameVariance = 500.0; // Y-channel variance; low = blurry

  // ── Capture / analyse ─────────────────────────────────────────────────────
  bool _isCapturing = false;
  bool _isAnalyzing = false;
  String _analyzeStatus = 'Reading colour values…';

  // ── White reference (Feature 3) ───────────────────────────────────────────
  List<double>? _whiteRef;

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _scanLineCtrl;
  late Animation<double>   _scanLineAnim;
  late AnimationController _cornerCtrl;
  late Animation<double>   _cornerAnim;

  // ── Adaptive match threshold (strict when lighting is OK) ─────────────────
  double get _matchThreshold {
    if (_qualityIssue == _QualityIssue.none) return 35.0;
    return 55.0;
  }

  // ── Services ──────────────────────────────────────────────────────────────
  final _imgService   = ImageAnalysisService();
  final _calService   = CalibrationService();
  final _logicService = SoilLogicService();

  // ─────────────────────────────────────────────────────────────────────────

  Color get _stateColor {
    switch (_detectState) {
      case _DetectState.soilFound: return const Color(0xFF4CAF50);
      case _DetectState.noSoil:   return const Color(0xFFFF5722);
      case _DetectState.scanning: return const Color(0xFFFFD600);
    }
  }

  String get _stateLabel {
    switch (_detectState) {
      case _DetectState.soilFound: return 'Soil Detected  ✓';
      case _DetectState.noSoil:   return 'No soil — aim at sample';
      case _DetectState.scanning: return 'Scanning…';
    }
  }

  Widget _buildTestTypeBadge() {
    final t = widget.testType;
    if (t == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.color.withOpacity(0.7), width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: t.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          t.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }

  // ── Quality helpers (Feature 5) ───────────────────────────────────────────

  Color get _qualityColor {
    switch (_qualityIssue) {
      case _QualityIssue.tooDark:   return Colors.orange;
      case _QualityIssue.tooBright: return Colors.amber;
      case _QualityIssue.blurry:    return Colors.red;
      case _QualityIssue.none:      return Colors.green;
    }
  }

  String get _qualityLabel {
    switch (_qualityIssue) {
      case _QualityIssue.tooDark:   return 'Too dark — add light';
      case _QualityIssue.tooBright: return 'Too bright — reduce glare';
      case _QualityIssue.blurry:    return 'Blurry — hold steady';
      case _QualityIssue.none:      return 'Lighting OK';
    }
  }

  IconData get _qualityIcon {
    switch (_qualityIssue) {
      case _QualityIssue.tooDark:   return Icons.dark_mode_outlined;
      case _QualityIssue.tooBright: return Icons.wb_sunny_outlined;
      case _QualityIssue.blurry:    return Icons.blur_on_outlined;
      case _QualityIssue.none:      return Icons.check_circle_outline;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);

    _scanLineCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _scanLineAnim =
        CurvedAnimation(parent: _scanLineCtrl, curve: Curves.linear);

    _cornerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _cornerAnim =
        CurvedAnimation(parent: _cornerCtrl, curve: Curves.easeOut);

    _loadWhiteRef().then((_) {
      if (widget.initialImagePath != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _analyzeImage(File(widget.initialImagePath!));
        });
      } else {
        _initCamera();
      }
    });
  }

  @override
  void dispose() {
    _ctrl?.stopImageStream();
    _ctrl?.dispose();
    _pulseCtrl.dispose();
    _scanLineCtrl.dispose();
    _cornerCtrl.dispose();
    super.dispose();
  }

  // ── Load white reference ──────────────────────────────────────────────────

  Future<void> _loadWhiteRef() async {
    final ref = await _calService.loadWhiteReference();
    if (mounted) setState(() => _whiteRef = ref);
  }

  // ── Camera init ───────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    // camera plugin only supports Android & iOS
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (mounted) {
        setState(() {
          _camError = true;
          _errorMsg = 'Camera is not supported on this platform.\nUse the Gallery option to select a photo.';
        });
      }
      return;
    }
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() { _camError = true; _errorMsg = 'No cameras found.'; });
        return;
      }
      final rear = _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      _ctrl = CameraController(
        rear,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _ctrl!.initialize();
      await _ctrl!.setFlashMode(FlashMode.off);
      if (!mounted) return;
      setState(() { _camReady = true; _camError = false; });
      _startImageStream();
    } on CameraException catch (e) {
      setState(() {
        _camError = true;
        _errorMsg = e.description ?? 'Camera failed to start.';
      });
    }
  }

  // ── Image stream ──────────────────────────────────────────────────────────

  void _startImageStream() {
    _ctrl?.startImageStream((CameraImage frame) {
      _frameCount++;
      if (_frameCount % _kSampleEvery != 0) return;
      if (_streamProcessing || _isCapturing || _isAnalyzing) return;
      _streamProcessing = true;
      _analyzeFrame(frame);
    });
  }

  void _analyzeFrame(CameraImage frame) {
    try {
      final w = frame.width;
      final h = frame.height;

      final x0 = (w * 0.30).toInt();
      final x1 = (w * 0.70).toInt();
      final y0 = (h * 0.30).toInt();
      final y1 = (h * 0.70).toInt();

      double r = 128, g = 128, b = 128;
      double yAvgVal = 128.0;

      final fmt = frame.format.group;

      if (fmt == ImageFormatGroup.bgra8888) {
        final plane = frame.planes[0];
        double rS = 0, gS = 0, bS = 0;
        int cnt = 0;
        for (int py = y0; py < y1; py += 6) {
          for (int px = x0; px < x1; px += 6) {
            final i = py * plane.bytesPerRow + px * 4;
            if (i + 2 < plane.bytes.length) {
              bS += plane.bytes[i];
              gS += plane.bytes[i + 1];
              rS += plane.bytes[i + 2];
              cnt++;
            }
          }
        }
        if (cnt > 0) { r = rS / cnt; g = gS / cnt; b = bS / cnt; }
        yAvgVal = (0.2126 * r + 0.7152 * g + 0.0722 * b);
      } else {
        // YUV — compute from Y plane
        final yPlane = frame.planes[0];
        double yS = 0, varS = 0;
        int yCnt = 0;

        for (int py = y0; py < y1; py += 6) {
          for (int px = x0; px < x1; px += 6) {
            final i = py * yPlane.bytesPerRow + px;
            if (i < yPlane.bytes.length) {
              final yv = yPlane.bytes[i] & 0xFF;
              yS += yv;
              yCnt++;
            }
          }
        }

        yAvgVal = yCnt > 0 ? yS / yCnt : 128.0;

        // Second pass for variance (blur detection) — Feature 5
        for (int py = y0; py < y1; py += 6) {
          for (int px = x0; px < x1; px += 6) {
            final i = py * yPlane.bytesPerRow + px;
            if (i < yPlane.bytes.length) {
              final diff = (yPlane.bytes[i] & 0xFF) - yAvgVal;
              varS += diff * diff;
            }
          }
        }

        final variance = yCnt > 0 ? varS / yCnt : 500.0;

        double uAvg = 128.0, vAvg = 128.0;
        if (frame.planes.length >= 2) {
          final plane1 = frame.planes[1];
          final pixStride = plane1.bytesPerPixel ?? 1;
          final interleaved = pixStride == 2;
          double u1S = 0, v1S = 0;
          int uvCnt = 0;
          for (int py = y0 ~/ 2; py < y1 ~/ 2; py += 3) {
            for (int px = x0 ~/ 2; px < x1 ~/ 2; px += 3) {
              if (interleaved) {
                final idx = py * plane1.bytesPerRow + px * 2;
                if (idx + 1 < plane1.bytes.length) {
                  v1S += plane1.bytes[idx] & 0xFF;
                  u1S += plane1.bytes[idx + 1] & 0xFF;
                  uvCnt++;
                }
              } else {
                final idx = py * plane1.bytesPerRow + px;
                if (idx < plane1.bytes.length) {
                  u1S += plane1.bytes[idx] & 0xFF;
                  uvCnt++;
                }
                if (frame.planes.length >= 3) {
                  final plane2 = frame.planes[2];
                  final vIdx = py * plane2.bytesPerRow + px;
                  if (vIdx < plane2.bytes.length) {
                    v1S += plane2.bytes[vIdx] & 0xFF;
                  }
                }
              }
            }
          }
          if (uvCnt > 0) { uAvg = u1S / uvCnt; vAvg = v1S / uvCnt; }
        }

        r = (yAvgVal + 1.402  * (vAvg - 128)).clamp(0, 255).toDouble();
        g = (yAvgVal - 0.344  * (uAvg - 128) - 0.714 * (vAvg - 128)).clamp(0, 255).toDouble();
        b = (yAvgVal + 1.772  * (uAvg - 128)).clamp(0, 255).toDouble();

        // ── Feature 5: update quality metrics ─────────────────────────────
        if (mounted) {
          final bNorm = yAvgVal / 255.0;
          _QualityIssue issue;
          if (bNorm < 0.15)      issue = _QualityIssue.tooDark;
          else if (bNorm > 0.90) issue = _QualityIssue.tooBright;
          else if (variance < 100) issue = _QualityIssue.blurry;
          else                   issue = _QualityIssue.none;

          // Only call setState if something changed to avoid unnecessary
          // rebuilds every 20 frames.
          if (issue != _qualityIssue ||
              (bNorm - _brightness).abs() > 0.05 ||
              (variance - _frameVariance).abs() > 50) {
            setState(() {
              _brightness    = bNorm;
              _frameVariance = variance;
              _qualityIssue  = issue;
            });
          }
        }
      }

      final confidence = _calcSoilConfidence(r, g, b);

      if (!mounted) { _streamProcessing = false; return; }

      final prev = _detectState;
      setState(() {
        _soilConfidence = confidence;
        if (confidence >= 0.55) {
          _detectState = _DetectState.soilFound;
        } else if (confidence >= 0.30) {
          _detectState = _DetectState.scanning;
        } else {
          _detectState = _DetectState.noSoil;
        }
      });

      if (prev != _detectState) _cornerCtrl.forward(from: 0);
    } catch (_) {}
    _streamProcessing = false;
  }

  double _calcSoilConfidence(double r, double g, double b) {
    // Hard rejects — clearly not soil
    if (b > r + 18 && b > g) return 0.05;
    if (g > r + 18 && g > b + 10) return 0.05;
    if (r > 230 && g > 230 && b > 230) return 0.05;
    if (r < 15 && g < 15 && b < 15) return 0.0;

    final rf = r / 255, gf = g / 255, bf = b / 255;
    final maxC = [rf, gf, bf].reduce(math.max);
    final minC = [rf, gf, bf].reduce(math.min);
    final delta = maxC - minC;
    final s = maxC == 0 ? 0.0 : delta / maxC;

    if (s < 0.08) return 0.05;

    double h = 0;
    if (delta > 0) {
      if (maxC == rf)      h = 60 * (((gf - bf) / delta) % 6);
      else if (maxC == gf) h = 60 * (((bf - rf) / delta) + 2);
      else                 h = 60 * (((rf - gf) / delta) + 4);
      if (h < 0) h += 360;
    }

    double score = 0.0;

    // Hue score — soil is earthy (reds, oranges, yellows, warm browns: 0–60°)
    if (h >= 0 && h <= 40)       score += 0.40;  // red-orange (iron-rich soil)
    else if (h > 40 && h <= 60)  score += 0.35;  // orange-yellow (sandy/clay)
    else if (h > 60 && h <= 90)  score += 0.15;  // yellow-green (marginal)
    else if (h > 300)            score += 0.15;  // reddish-purple (some soils)
    else return 0.05;                             // green/blue/cyan — not soil

    // RGB order score — soil must have R dominance (brown = R > G > B)
    if (r >= g && g >= b && r > b + 15) score += 0.30; // classic brown
    else if (r >= g && r > b + 10)      score += 0.15; // reddish
    else return 0.05;                                   // not R-dominant — reject

    // Saturation score — soil is earthy, not vivid neon
    if (s >= 0.12 && s <= 0.60) score += 0.20;  // ideal earthy range
    else if (s > 0.60)          score += 0.05;  // too vivid (painted surface)

    // Brightness — soil should be mid-range, not glowing
    if (maxC >= 0.15 && maxC <= 0.80) score += 0.10;

    return score.clamp(0.0, 1.0);
  }

  // ── Torch ─────────────────────────────────────────────────────────────────

  Future<void> _toggleTorch() async {
    if (_ctrl == null || !_camReady) return;
    final next = !_torchOn;
    try {
      await _ctrl!.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      setState(() => _torchOn = next);
    } catch (_) {}
  }

  // ── Capture ───────────────────────────────────────────────────────────────

  Future<void> _capture() async {
    if (_ctrl == null || !_camReady || _isCapturing || _isAnalyzing) return;
    if (_detectState != _DetectState.soilFound) {
      _showValidationWarning();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isCapturing = true);

    try { await _ctrl!.stopImageStream(); } catch (_) {}

    try {
      if (_torchOn) await _ctrl!.setFlashMode(FlashMode.off);
      try {
        await _ctrl!.setExposureMode(ExposureMode.locked);
        await Future.delayed(const Duration(milliseconds: 150));
      } catch (_) {}
      final xfile = await _ctrl!.takePicture();
      try { await _ctrl!.setExposureMode(ExposureMode.auto); } catch (_) {}
      if (_torchOn) await _ctrl!.setFlashMode(FlashMode.torch);
      setState(() { _isCapturing = false; _isAnalyzing = true; });
      await _analyzeImage(File(xfile.path));
    } catch (e) {
      setState(() { _isCapturing = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Capture failed: $e'),
          backgroundColor: Colors.red[700],
        ));
      }
      try { _startImageStream(); } catch (_) {}
    }
  }

  void _showValidationWarning() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
        SizedBox(width: 10),
        Expanded(child: Text('Aim camera at soil to capture')),
      ]),
      backgroundColor: const Color(0xFFE65100),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Gallery ───────────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
      if (picked != null && mounted) {
        setState(() { _isAnalyzing = true; _analyzeStatus = 'Loading image…'; });
        await _analyzeImage(File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gallery error: $e'),
          backgroundColor: Colors.red[700],
        ));
      }
    }
  }

  // ── Analysis pipeline ─────────────────────────────────────────────────────
  //
  //  Changes vs original:
  //   • Passes _whiteRef to getAverageRGB for white-patch correction (Feat 3)
  //   • Uses _logicService.score(n, p, k, ph: ph) — pH-weighted (Feat 4)
  //   • Score normalisation updated to 4–12 range (Feat 4)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _analyzeImage(File file) async {
    if (!mounted) return;

    try {
      // Step 1: Read RGB with white-patch correction (Feature 3)
      _setStatus('Reading colour values…');
      final sampleRGB = await _imgService.getAverageRGB(
        file.path,
        whiteRef: _whiteRef,
      );

      // Step 2: Load calibration
      _setStatus('Loading calibration data…');
      final calibrationRaw = await _calService.loadCalibration();

      String nitrogenLevel, phosphorusLevel, potassiumLevel;
      double ph;
      bool isHeuristic = false;

      if (calibrationRaw == null || calibrationRaw.isEmpty) {
        if (!mounted) return;
        setState(() => _isAnalyzing = false);
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.science_outlined,
                color: Color(0xFFD68910), size: 32),
            title: const Text('Calibration required'),
            content: const Text(
              'No calibration data was found. Without it, nutrient and pH '
                  'readings cannot be determined accurately.\n\n'
                  'Please calibrate the app with your soil test kit reference '
                  'colours before analysing a sample.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CalibrationScreen()),
                  );
                },
                child: const Text('Go to Calibration'),
              ),
            ],
          ),
        );
        return;
      }

      _setStatus('Matching nutrient levels…');
      nitrogenLevel   = _matchNutrient(sampleRGB, calibrationRaw, 'Nitrogen');
      phosphorusLevel = _matchNutrient(sampleRGB, calibrationRaw, 'Phosphorus');
      potassiumLevel  = _matchNutrient(sampleRGB, calibrationRaw, 'Potassium');
      ph              = _matchPh(sampleRGB, calibrationRaw);

      // Step 3: pH-weighted score (Feature 4)
      // Range 4–12 (NPK 3–9 + pH 1–3) → normalised to 0–100 %
      _setStatus('Computing soil health score…');
      final rawScore = _logicService.score(
        nitrogenLevel,
        phosphorusLevel,
        potassiumLevel,
        ph: ph,
      );
      final overallScore = (((rawScore - 4) / 8) * 100).clamp(0, 100).toDouble();
      final status = _statusLabel(overallScore);

      // Step 4: Navigate
      final soilResult = SoilResult(
        soilType:        _inferSoilType(nitrogenLevel, phosphorusLevel, potassiumLevel, ph),
        date:            DateTime.now(),
        overallScore:    overallScore,
        status:          status,
        nitrogenLevel:   nitrogenLevel,
        phosphorusLevel: phosphorusLevel,
        potassiumLevel:  potassiumLevel,
        ph:              double.parse(ph.toStringAsFixed(1)),
        imagePath:       file.path,
        isHeuristic:     isHeuristic,
        testType:        widget.testType,
      );

      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CameraResultScreen(result: soilResult)),
      );

    } catch (e) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      try { _startImageStream(); } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Analysis failed: $e'),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 4),
      ));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setStatus(String msg) {
    if (mounted) setState(() => _analyzeStatus = msg);
  }

  String _matchNutrient(
      List<double> sampleRGB,
      Map<String, dynamic> calibrationRaw,
      String nutrient,
      ) {
    final nutrientData = calibrationRaw[nutrient];
    if (nutrientData == null) return 'Medium';

    final levels = Map<String, List<double>>.fromEntries(
      (nutrientData as Map<String, dynamic>).entries.map((e) {
        final vals = (e.value as List).map((v) => (v as num).toDouble()).toList();
        return MapEntry(e.key, vals);
      }),
    );

    final matched = _imgService.matchLevel(sampleRGB, levels, threshold: _matchThreshold);
    switch (matched.toUpperCase()) {
      case 'HIGH':   return 'High';
      case 'MEDIUM': return 'Medium';
      case 'LOW':    return 'Low';
      default:       return 'Medium';
    }
  }

  double _matchPh(List<double> sampleRGB, Map<String, dynamic> calibrationRaw) {
    final phData = calibrationRaw['pH'];
    if (phData != null) {
      final levels = Map<String, List<double>>.fromEntries(
        (phData as Map<String, dynamic>).entries.map((e) {
          final vals = (e.value as List).map((v) => (v as num).toDouble()).toList();
          return MapEntry(e.key, vals);
        }),
      );
      final matched = _imgService.matchLevel(sampleRGB, levels, threshold: _matchThreshold);
      switch (matched.toUpperCase()) {
        case 'LOW':    return 5.0;
        case 'MEDIUM': return 6.2;
        case 'HIGH':   return 7.5;
        default:       return 6.2;
      }
    }
    return 6.2;
  }

  String _inferSoilType(String n, String p, String k, double ph) =>
      _logicService.inferSoilType(n, p, k, ph);

  String _statusLabel(double score) {
    if (score >= 70) return 'Good Nutrient Level';
    if (score >= 45) return 'Moderate Nutrient';
    if (score >= 25) return 'Low Nutrient';
    return 'Critical Low Nutrient';
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    const boxTopRatio = 0.17;
    const boxHRatio   = 0.54;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [

          // ── Live preview ────────────────────────────────────────────────
          if (_camReady && _ctrl != null)
            Positioned.fill(
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: size.width,
                      height: size.width * _ctrl!.value.aspectRatio,
                      child: CameraPreview(_ctrl!),
                    ),
                  ),
                ),
              ),
            ),

          if (!_camReady && !_camError)
            const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF7DB560)),
                SizedBox(height: 16),
                Text('Starting camera…',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            )),

          if (_camError) _buildErrorView(),

          if (_camReady)
            Positioned.fill(child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center, radius: 1.1,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            )),

          // ── Scan line ───────────────────────────────────────────────────
          if (_camReady && !_isAnalyzing)
            AnimatedBuilder(
              animation: _scanLineAnim,
              builder: (_, __) {
                final top  = size.height * boxTopRatio;
                final boxH = size.height * boxHRatio;
                return Positioned(
                  top: top + _scanLineAnim.value * boxH,
                  left: size.width * 0.07,
                  right: size.width * 0.07,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        _stateColor.withOpacity(0.85),
                        Colors.transparent,
                      ]),
                      boxShadow: [BoxShadow(
                        color: _stateColor.withOpacity(0.45),
                        blurRadius: 8,
                      )],
                    ),
                  ),
                );
              },
            ),

          // ── Corner brackets ─────────────────────────────────────────────
          if (_camReady)
            Positioned(
              top: size.height * boxTopRatio,
              left: size.width * 0.06,
              right: size.width * 0.06,
              height: size.height * boxHRatio,
              child: AnimatedBuilder(
                animation: _cornerAnim,
                builder: (_, __) => CustomPaint(
                  painter: _CornerBracketPainter(
                    color: _stateColor,
                    progress: _cornerAnim.value,
                  ),
                ),
              ),
            ),

          // ── Soil-detection badge ────────────────────────────────────────
          if (_camReady)
            Positioned(
              top: size.height * boxTopRatio - 44,
              left: 0, right: 0,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Container(
                    key: ValueKey(_detectState),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _stateColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _stateColor.withOpacity(0.55), width: 1.2),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _stateColor
                                .withOpacity(0.5 + 0.5 * _pulseCtrl.value),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      _buildTestTypeBadge(),
                      const SizedBox(height: 8),
                      Text(_stateLabel,
                          style: TextStyle(
                            color: _stateColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          )),
                    ]),
                  ),
                ),
              ),
            ),

          // ── Live quality feedback (Feature 5) ───────────────────────────
          // Shown below the confidence bar so it's always visible.
          if (_camReady && !_isAnalyzing)
            Positioned(
              bottom: botPad + 148,
              left: size.width * 0.06,
              right: size.width * 0.06,
              child: Column(children: [
                // Soil confidence bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Soil Match',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11)),
                    Text('${(_soilConfidence * 100).toInt()}%',
                        style: TextStyle(
                            color: _stateColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _soilConfidence,
                    minHeight: 5,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(_stateColor),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Quality row ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quality badge
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        key: ValueKey(_qualityIssue),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _qualityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _qualityColor.withOpacity(0.5),
                              width: 1),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_qualityIcon,
                              color: _qualityColor, size: 12),
                          const SizedBox(width: 5),
                          Text(_qualityLabel,
                              style: TextStyle(
                                  color: _qualityColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),

                    // Brightness mini-bar
                    Row(children: [
                      Text('Brightness',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 10)),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 60,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _brightness,
                            minHeight: 4,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation(
                              _qualityIssue == _QualityIssue.none
                                  ? Colors.greenAccent
                                  : _qualityColor,
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ]),
            ),

          // ── Analysing overlay ────────────────────────────────────────────
          if (_isAnalyzing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.75),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 56, height: 56,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: Color(0xFF7DB560)),
                    ),
                    const SizedBox(height: 20),
                    const Text('Analysing soil sample…',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _analyzeStatus,
                        key: ValueKey(_analyzeStatus),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Top bar ──────────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              padding: EdgeInsets.only(
                  top: topPad + 6, left: 8, right: 16, bottom: 16),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                        color: Colors.white12,
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 20),
                  ),
                ),
                const Spacer(),
                // White-ref indicator
                if (_whiteRef != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.wb_auto,
                          color: Colors.white70, size: 12),
                      SizedBox(width: 4),
                      Text('WB',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('HD',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          ),

          // ── Hint text ────────────────────────────────────────────────────
          if (_camReady && !_isAnalyzing)
            Positioned(
              bottom: botPad + 124,
              left: 0, right: 0,
              child: Center(
                child: Text(
                  _detectState == _DetectState.soilFound
                      ? 'Ready — tap shutter to capture'
                      : 'Point camera at soil sample',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55), fontSize: 12),
                ),
              ),
            ),

          // ── Bottom bar ───────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black, Colors.transparent],
                ),
              ),
              padding: EdgeInsets.only(
                  bottom: botPad + 20, top: 20, left: 28, right: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  _BottomActionBtn(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: _isAnalyzing ? null : _pickFromGallery,
                  ),

                  GestureDetector(
                    onTap: _isCapturing || _isAnalyzing ? null : _capture,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) {
                        final canShoot =
                            _detectState == _DetectState.soilFound &&
                                !_isCapturing &&
                                !_isAnalyzing;
                        return Container(
                          width: 74, height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: canShoot
                                ? Color.lerp(
                                const Color(0xFFFFD600),
                                const Color(0xFFFFAA00),
                                _pulseCtrl.value)!
                                : Colors.white24,
                            boxShadow: canShoot
                                ? [BoxShadow(
                              color: const Color(0xFFFFD600)
                                  .withOpacity(0.35 + 0.25 * _pulseCtrl.value),
                              blurRadius: 24,
                              spreadRadius: 4,
                            )]
                                : [],
                          ),
                          child: Icon(
                            _isCapturing
                                ? Icons.hourglass_top_rounded
                                : Icons.camera_alt_rounded,
                            color: canShoot ? Colors.black87 : Colors.white38,
                            size: 30,
                          ),
                        );
                      },
                    ),
                  ),

                  _BottomActionBtn(
                    icon: _torchOn
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    label: _torchOn ? 'Flash On' : 'Flash',
                    active: _torchOn,
                    onTap: _camReady && !_isAnalyzing ? _toggleTorch : null,
                  ),

                ],
              ),
            ),
          ),

        ]),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.no_photography_outlined,
                size: 44, color: Colors.red),
          ),
          const SizedBox(height: 20),
          const Text('Camera Unavailable',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_errorMsg,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _initCamera,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E7A3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library_outlined,
                color: Colors.grey),
            label: const Text('Use Gallery',
                style: TextStyle(color: Colors.grey)),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Corner bracket painter (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double progress;
  const _CornerBracketPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.lerp(Colors.white38, color, progress)!
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = Colors.white.withOpacity(0.06)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    const arm = 32.0;
    _corner(canvas, paint, Offset.zero, arm, 1, 1);
    _corner(canvas, paint, Offset(size.width, 0), arm, -1, 1);
    _corner(canvas, paint, Offset(0, size.height), arm, 1, -1);
    _corner(canvas, paint, Offset(size.width, size.height), arm, -1, -1);
  }

  void _corner(Canvas c, Paint p, Offset o, double len, int dx, int dy) {
    final path = Path()
      ..moveTo(o.dx + dx * len, o.dy)
      ..lineTo(o.dx, o.dy)
      ..lineTo(o.dx, o.dy + dy * len);
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_CornerBracketPainter old) =>
      old.color != color || old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bottom action button (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class _BottomActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  const _BottomActionBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 62,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFFFD600).withOpacity(0.2)
                : Colors.white12,
            borderRadius: BorderRadius.circular(12),
            border: active
                ? Border.all(
                color: const Color(0xFFFFD600).withOpacity(0.6),
                width: 1.2)
                : null,
          ),
          child: Icon(icon,
              color: active ? const Color(0xFFFFD600) : Colors.white70,
              size: 22),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: TextStyle(
                color: active ? const Color(0xFFFFD600) : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}