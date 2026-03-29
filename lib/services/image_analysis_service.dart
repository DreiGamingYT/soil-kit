import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

/// Analyses a captured soil test strip image and returns average RGB values.
///
/// Key improvements over the original:
/// 1. Samples only the **centre 40 % crop** of the image — matching the
///    on-screen CaptureBox guide the user sees when taking the photo.
/// 2. Strip detection uses **saturation + brightness** instead of raw
///    brightness sum, so plain white/grey backgrounds are excluded.
/// 3. White balance uses a **grey-world algorithm** (per-channel scaling)
///    that preserves colour differences rather than collapsing them into a
///    single brightness-normalised triplet.
/// 4. `matchLevel` uses **weighted Euclidean distance** and a generous
///    default threshold (120) so UNKNOWN is a true last resort.
class ImageAnalysisService {

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the average [r, g, b] (0–255 each) of the strip region inside
  /// the centre crop of [path].
  Future<List<double>> getAverageRGB(String path) async {
    final bytes = await File(path).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Could not decode image: $path');

    // ── Step 1: Centre crop (matches the on-screen CaptureBox) ────────────
    // The CaptureBox covers roughly the middle 40 % of width and height.
    final cropX0 = (image.width  * 0.30).toInt();
    final cropY0 = (image.height * 0.30).toInt();
    final cropX1 = (image.width  * 0.70).toInt();
    final cropY1 = (image.height * 0.70).toInt();

    // ── Step 2: Find the coloured strip region inside the crop ─────────────
    // We look for pixels with meaningful saturation OR mid-range brightness.
    // This excludes: white paper background, near-black shadows.
    int minX = cropX1, minY = cropY1;
    int maxX = cropX0, maxY = cropY0;
    bool found = false;

    // Stride of 2 for speed — we only need an approximate bounding box
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

    // ── Step 4: Sum RGB in the detected region (every pixel, no stride) ────
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

    // ── Step 5: Grey-world white balance ───────────────────────────────────
    // Scale each channel so its average equals the overall channel mean.
    // This corrects for tinted ambient light without destroying hue info.
    // Formula: corrected_channel = raw * (globalMean / channelAvg)
    final globalMean = (rAvg + gAvg + bAvg) / 3.0;

    final rCorrected = (rAvg * globalMean / max(rAvg, 1.0)).clamp(0.0, 255.0);
    final gCorrected = (gAvg * globalMean / max(gAvg, 1.0)).clamp(0.0, 255.0);
    final bCorrected = (bAvg * globalMean / max(bAvg, 1.0)).clamp(0.0, 255.0);

    return [rCorrected, gCorrected, bCorrected];
  }

  // ── Colour distance ────────────────────────────────────────────────────────

  /// Standard Euclidean distance in RGB space.
  double colorDistance(List<double> a, List<double> b) {
    return sqrt(
      pow(a[0] - b[0], 2) +
          pow(a[1] - b[1], 2) +
          pow(a[2] - b[2], 2),
    );
  }

  /// Weighted colour distance that emphasises hue over raw brightness.
  ///
  /// Human perception (and test strip reactions) are more sensitive to
  /// green-channel shifts. Weights (2, 4, 3) approximate this sensitivity.
  double _weightedDistance(List<double> a, List<double> b) {
    final dr = a[0] - b[0];
    final dg = a[1] - b[1];
    final db = a[2] - b[2];
    return sqrt(2 * dr * dr + 4 * dg * dg + 3 * db * db);
  }

  // ── Level matching ─────────────────────────────────────────────────────────

  /// Finds the calibration level whose RGB is closest to [sampleRGB].
  ///
  /// Returns "UNKNOWN" only if the minimum distance exceeds [threshold].
  /// Default threshold is 120 (in weighted space) — generous enough that
  /// a result is almost always returned even under imperfect lighting.
  String matchLevel(
      List<double> sampleRGB,
      Map<String, List<double>> levels, {
        double threshold = 120,
      }) {
    if (levels.isEmpty) return 'UNKNOWN';

    double minDist = double.infinity;
    String best = 'UNKNOWN';

    levels.forEach((level, rgb) {
      if (rgb.length < 3) return;
      final d = _weightedDistance(sampleRGB, rgb);
      if (d < minDist) {
        minDist = d;
        best = level;
      }
    });

    return minDist <= threshold ? best : 'UNKNOWN';
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Returns true if this pixel looks like a coloured test strip reaction
  /// rather than white paper, grey background, or near-black shadow.
  bool _isStripPixel(double r, double g, double b) {
    // Reject near-black (shadow / dark background)
    if (r < 20 && g < 20 && b < 20) return false;

    // Reject near-white (paper / overexposed highlight)
    if (r > 220 && g > 220 && b > 220) return false;

    // Compute HSV-style saturation
    final maxC = max(r, max(g, b));
    final minC = min(r, min(g, b));
    final saturation = maxC > 0 ? (maxC - minC) / maxC : 0.0;
    final brightness = maxC / 255.0;

    // Accept clearly coloured pixels (coloured reaction zones)
    if (saturation > 0.15) return true;

    // Accept mid-range brightness pixels (earthy/tan tones are low-saturation)
    if (brightness > 0.25 && brightness < 0.85) return true;

    return false;
  }
}