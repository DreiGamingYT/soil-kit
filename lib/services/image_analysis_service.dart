import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

class ImageAnalysisService {

  Future<List<double>> getAverageRGB(
      String path, {
        List<double>? whiteRef,
      }) async {
    final bytes = await File(path).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Could not decode image: $path');

    // ── Step 1: Centre crop (matches the on-screen CaptureBox) ────────────
    final cropX0 = (image.width  * 0.30).toInt();
    final cropY0 = (image.height * 0.30).toInt();
    final cropX1 = (image.width  * 0.70).toInt();
    final cropY1 = (image.height * 0.70).toInt();

    // ── Step 2: Find the coloured strip region inside the crop ─────────────
    int minX = cropX1, minY = cropY1;
    int maxX = cropX0, maxY = cropY0;
    bool found = false;

    for (int y = cropY0; y < cropY1; y += 2) {
      for (int x = cropX0; x < cropX1; x += 2) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        if (_isStripPixel(r, g, b)) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
          found = true;
        }
      }
    }

    // ── Step 3: Fallback to full centre crop if no strip found ─────────────
    if (!found || maxX - minX < 10 || maxY - minY < 10) {
      minX = cropX0; minY = cropY0;
      maxX = cropX1; maxY = cropY1;
    }

    // ── Step 4: Sum RGB in the detected region ─────────────────────────────
    double rSum = 0, gSum = 0, bSum = 0;
    int count = 0;

    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        final pixel = image.getPixel(x, y);
        rSum += pixel.r.toDouble();
        gSum += pixel.g.toDouble();
        bSum += pixel.b.toDouble();
        count++;
      }
    }

    if (count == 0) return [128.0, 128.0, 128.0];

    final rAvg = rSum / count;
    final gAvg = gSum / count;
    final bAvg = bSum / count;

    if (whiteRef != null && whiteRef.length == 3) {
      return correctWithWhiteRef([rAvg, gAvg, bAvg], whiteRef);
    }

    // Grey-world fallback
    final globalMean = (rAvg + gAvg + bAvg) / 3.0;
    final rCorrected = (rAvg * globalMean / max(rAvg, 1.0)).clamp(0.0, 255.0);
    final gCorrected = (gAvg * globalMean / max(gAvg, 1.0)).clamp(0.0, 255.0);
    final bCorrected = (bAvg * globalMean / max(bAvg, 1.0)).clamp(0.0, 255.0);

    return [rCorrected, gCorrected, bCorrected];
  }

  List<double> correctWithWhiteRef(
      List<double> sampleRGB,
      List<double> whiteRef,
      ) {
    final scaleR = whiteRef[0] > 1.0 ? 255.0 / whiteRef[0] : 1.0;
    final scaleG = whiteRef[1] > 1.0 ? 255.0 / whiteRef[1] : 1.0;
    final scaleB = whiteRef[2] > 1.0 ? 255.0 / whiteRef[2] : 1.0;

    return [
      (sampleRGB[0] * scaleR).clamp(0.0, 255.0),
      (sampleRGB[1] * scaleG).clamp(0.0, 255.0),
      (sampleRGB[2] * scaleB).clamp(0.0, 255.0),
    ];
  }

  // ── Colour distance (public, kept for backwards compatibility) ─────────────

  double colorDistance(List<double> a, List<double> b) {
    return sqrt(
      pow(a[0] - b[0], 2) +
          pow(a[1] - b[1], 2) +
          pow(a[2] - b[2], 2),
    );
  }

  String matchLevel(
      List<double> sampleRGB,
      Map<String, List<double>> levels, {
        double threshold = 35.0,
      }) {
    if (levels.isEmpty) return 'UNKNOWN';

    final sampleLab = _rgbToLab(sampleRGB[0], sampleRGB[1], sampleRGB[2]);

    double minDist = double.infinity;
    String best = 'UNKNOWN';

    levels.forEach((level, rgb) {
      if (rgb.length < 3) return;
      final calLab = _rgbToLab(rgb[0], rgb[1], rgb[2]);
      final d = _deltaE94(sampleLab, calLab);
      if (d < minDist) {
        minDist = d;
        best = level;
      }
    });

    return minDist <= threshold ? best : 'UNKNOWN';
  }

  // ── CIELAB conversion ──────────────────────────────────────────────────────

  List<double> _rgbToLab(double r, double g, double b) {
    double rN = r / 255.0;
    double gN = g / 255.0;
    double bN = b / 255.0;

    rN = rN <= 0.04045 ? rN / 12.92 : pow((rN + 0.055) / 1.055, 2.4).toDouble();
    gN = gN <= 0.04045 ? gN / 12.92 : pow((gN + 0.055) / 1.055, 2.4).toDouble();
    bN = bN <= 0.04045 ? bN / 12.92 : pow((bN + 0.055) / 1.055, 2.4).toDouble();

    final x = rN * 0.4124564 + gN * 0.3575761 + bN * 0.1804375;
    final y = rN * 0.2126729 + gN * 0.7151522 + bN * 0.0721750;
    final z = rN * 0.0193339 + gN * 0.1191920 + bN * 0.9503041;

    final fx = _labF(x / 0.95047);
    final fy = _labF(y / 1.00000);
    final fz = _labF(z / 1.08883);

    final L = 116.0 * fy - 16.0;
    final a = 500.0 * (fx - fy);
    final labB = 200.0 * (fy - fz);

    return [L, a, labB];
  }

  double _labF(double t) {
    const epsilon = 0.008856;
    const kappa   = 7.787;
    return t > epsilon ? pow(t, 1.0 / 3.0).toDouble() : kappa * t + 16.0 / 116.0;
  }

  // ── Delta-E CIE94 (Feature 1) ──────────────────────────────────────────────

  double _deltaE94(List<double> lab1, List<double> lab2) {
    final L1 = lab1[0]; final a1 = lab1[1]; final b1 = lab1[2];
    final L2 = lab2[0]; final a2 = lab2[1]; final b2 = lab2[2];

    final deltaL = L1 - L2;
    final c1 = sqrt(a1 * a1 + b1 * b1);
    final c2 = sqrt(a2 * a2 + b2 * b2);
    final deltaC = c1 - c2;

    final deltaH2 = max(0.0,
      (a1 - a2) * (a1 - a2) + (b1 - b2) * (b1 - b2) - deltaC * deltaC,
    );
    final deltaH = sqrt(deltaH2);

    const kL = 1.0;
    const kC = 1.0;
    const kH = 1.0;

    final sL = 1.0;
    final sC = 1.0 + 0.045 * c2;
    final sH = 1.0 + 0.015 * c2;

    final termL = deltaL / (kL * sL);
    final termC = deltaC / (kC * sC);
    final termH = deltaH / (kH * sH);

    return sqrt(termL * termL + termC * termC + termH * termH);
  }

  // ── Strip pixel detection ──────────────────────────────────────────────────

  bool _isStripPixel(double r, double g, double b) {
    if (r < 20 && g < 20 && b < 20) return false;
    if (r > 220 && g > 220 && b > 220) return false;

    final maxC = max(r, max(g, b));
    final minC = min(r, min(g, b));
    final saturation = maxC > 0 ? (maxC - minC) / maxC : 0.0;
    final brightness = maxC / 255.0;

    if (saturation > 0.15) return true;
    if (brightness > 0.25 && brightness < 0.85) return true;

    return false;
  }
}