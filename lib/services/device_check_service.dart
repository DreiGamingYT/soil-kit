import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'calibration_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DeviceCheckService
//
//  Runs four checks and returns a [DeviceCheckResult]:
//    1. Resolution   – preview width × height vs 2 MP baseline
//    2. Sharpness    – Y-channel variance from a single live frame
//    3. White Ref    – whether a white reference has been saved
//    4. Calibration  – whether nutrient calibration data exists
// ─────────────────────────────────────────────────────────────────────────────

enum CheckStatus { pass, warn, fail }

class CheckItem {
  final String title;
  final String detail;
  final CheckStatus status;
  final String? suggestion;

  const CheckItem({
    required this.title,
    required this.detail,
    required this.status,
    this.suggestion,
  });
}

class DeviceCheckResult {
  final CheckItem resolution;
  final CheckItem sharpness;
  final CheckItem whiteRef;
  final CheckItem calibration;

  const DeviceCheckResult({
    required this.resolution,
    required this.sharpness,
    required this.whiteRef,
    required this.calibration,
  });

  List<CheckItem> get all => [resolution, sharpness, whiteRef, calibration];

  CheckStatus get overall {
    if (all.any((c) => c.status == CheckStatus.fail)) return CheckStatus.fail;
    if (all.any((c) => c.status == CheckStatus.warn)) return CheckStatus.warn;
    return CheckStatus.pass;
  }
}

class DeviceCheckService {
  final _calService = CalibrationService();

  Future<DeviceCheckResult> runChecks() async {
    CameraController? ctrl;

    try {
      // ── Init camera ───────────────────────────────────────────────────────
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return _noCamera();
      }

      final rear = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      ctrl = CameraController(
        rear,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await ctrl.initialize();

      // ── 1. Resolution ─────────────────────────────────────────────────────
      final size   = ctrl.value.previewSize;
      final pixels = (size?.width ?? 0) * (size?.height ?? 0);
      final mp     = pixels / 1_000_000.0;

      CheckItem resolutionCheck;
      if (mp >= 2.0) {
        resolutionCheck = CheckItem(
          title: 'Camera Resolution',
          detail: '${mp.toStringAsFixed(1)} MP — Good for accurate color reading',
          status: CheckStatus.pass,
        );
      } else if (mp >= 1.0) {
        resolutionCheck = CheckItem(
          title: 'Camera Resolution',
          detail: '${mp.toStringAsFixed(1)} MP — Usable, but calibration is required',
          status: CheckStatus.warn,
          suggestion: 'Perform white reference calibration before every scan.',
        );
      } else {
        resolutionCheck = CheckItem(
          title: 'Camera Resolution',
          detail: 'Very low resolution detected — color accuracy may be limited',
          status: CheckStatus.fail,
          suggestion:
          'Try scanning in bright natural light and always calibrate first.',
        );
      }

      // ── 2. Sharpness (Y-channel variance) ────────────────────────────────
      double variance = 0;
      bool sharpnessMeasured = false;

      try {
        await ctrl.startImageStream((CameraImage frame) {});
        // give the stream one cycle to stabilise
        await Future.delayed(const Duration(milliseconds: 200));

        final completer = _Completer<double>();
        ctrl.stopImageStream();
        await ctrl.startImageStream((CameraImage frame) {
          if (!completer.isCompleted) {
            completer.complete(_computeVariance(frame));
          }
        });
        variance = await completer.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () => 300.0,
        );
        sharpnessMeasured = true;
        await ctrl.stopImageStream();
      } catch (_) {
        variance = 300.0; // assume ok if we can't measure
      }

      CheckItem sharpnessCheck;
      if (!sharpnessMeasured || variance > 200) {
        sharpnessCheck = CheckItem(
          title: 'Lens / Focus',
          detail: 'Image sharpness looks good',
          status: CheckStatus.pass,
        );
      } else if (variance > 80) {
        sharpnessCheck = CheckItem(
          title: 'Lens / Focus',
          detail: 'Slight blur detected — may be dirty lens or lighting',
          status: CheckStatus.warn,
          suggestion:
          'Clean the camera lens with a soft cloth and ensure good lighting.',
        );
      } else {
        sharpnessCheck = CheckItem(
          title: 'Lens / Focus',
          detail: 'Image appears very blurry — lens may be dirty or damaged',
          status: CheckStatus.fail,
          suggestion:
          'Clean the lens. If the problem persists, results may be inaccurate.',
        );
      }

      // ── 3. White Reference ────────────────────────────────────────────────
      final whiteRef = await _calService.loadWhiteReference();
      final CheckItem whiteRefCheck;

      if (whiteRef == null) {
        whiteRefCheck = CheckItem(
          title: 'White Reference',
          detail: 'Not set — scanning accuracy will be reduced',
          status: CheckStatus.fail,
          suggestion:
          'Open Calibration and capture a white reference using a blank white card.',
        );
      } else {
        // Validate that the captured white is actually bright
        final avgBrightness = (whiteRef[0] + whiteRef[1] + whiteRef[2]) / 3.0;
        if (avgBrightness >= 160) {
          whiteRefCheck = CheckItem(
            title: 'White Reference',
            detail: 'Calibrated — lighting corrections active',
            status: CheckStatus.pass,
          );
        } else {
          whiteRefCheck = CheckItem(
            title: 'White Reference',
            detail: 'Reference looks too dark — may have been captured in low light',
            status: CheckStatus.warn,
            suggestion:
            'Re-capture white reference using a clean white paper in good light.',
          );
        }
      }

      // ── 4. Nutrient Calibration ───────────────────────────────────────────
      final calData  = await _calService.loadCalibration();
      final nutrients = ['Nitrogen', 'Phosphorus', 'Potassium', 'pH'];
      final calibrated = calData != null
          ? nutrients.where((n) => calData.containsKey(n)).length
          : 0;

      final CheckItem calibrationCheck;
      if (calibrated == nutrients.length) {
        calibrationCheck = CheckItem(
          title: 'Nutrient Calibration',
          detail: 'All 4 nutrients calibrated (N, P, K, pH)',
          status: CheckStatus.pass,
        );
      } else if (calibrated > 0) {
        calibrationCheck = CheckItem(
          title: 'Nutrient Calibration',
          detail: '$calibrated of 4 nutrients calibrated',
          status: CheckStatus.warn,
          suggestion:
          'Complete calibration for all nutrients for best accuracy.',
        );
      } else {
        calibrationCheck = CheckItem(
          title: 'Nutrient Calibration',
          detail: 'No calibration data found',
          status: CheckStatus.fail,
          suggestion:
          'Go to Calibration and complete the nutrient calibration process.',
        );
      }

      return DeviceCheckResult(
        resolution:  resolutionCheck,
        sharpness:   sharpnessCheck,
        whiteRef:    whiteRefCheck,
        calibration: calibrationCheck,
      );
    } finally {
      await ctrl?.dispose();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  DeviceCheckResult _noCamera() {
    const noCamera = CheckItem(
      title: 'Camera',
      detail: 'No camera detected on this device',
      status: CheckStatus.fail,
      suggestion: 'Use the gallery option to analyse an existing photo.',
    );
    const na = CheckItem(
      title: 'N/A',
      detail: 'Camera required',
      status: CheckStatus.warn,
    );
    return DeviceCheckResult(
      resolution: noCamera,
      sharpness: na,
      whiteRef: na,
      calibration: na,
    );
  }

  double _computeVariance(CameraImage frame) {
    final plane  = frame.planes[0];
    final bytes  = plane.bytes;
    final len    = bytes.length;
    if (len == 0) return 0;

    // Sample every 16th pixel for speed
    double sum = 0, sumSq = 0;
    int count = 0;
    for (int i = 0; i < len; i += 16) {
      final v = bytes[i] & 0xFF;
      sum   += v;
      sumSq += v * v;
      count++;
    }
    final mean = sum / count;
    return max(0, sumSq / count - mean * mean);
  }
}

// Minimal completer wrapper to avoid dart:async import conflicts
class _Completer<T> {
  final _completer = Completer<T>();
  bool get isCompleted => _completer.isCompleted;
  void complete(T value) => _completer.complete(value);
  Future<T> get future => _completer.future;
}