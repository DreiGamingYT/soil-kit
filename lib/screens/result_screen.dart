import 'package:flutter/material.dart';
import '../services/image_analysis_service.dart';
import '../services/calibration_service.dart';
import '../services/soil_logic_service.dart';
import 'dashboard_screen.dart';
import 'fertilizer_calculator_screen.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;

  const ResultScreen(this.imagePath);

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Map<String, String>? results;
  bool analyzing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      analyze();
    });
  }

  Future analyze() async {
    try {
      ImageAnalysisService imgService = ImageAnalysisService();
      CalibrationService calService = CalibrationService();
      SoilLogicService logic = SoilLogicService();

      // Analyze only the CaptureBox region
      final sampleRGB = await imgService.getAverageRGB(widget.imagePath);
      final calibration = await calService.loadCalibration();

      if (calibration == null || calibration.isEmpty) {
        setState(() {
          results = {"Error": "No calibration data found. Capture calibration first."};
          analyzing = false;
        });
        return;
      }

      Map<String, String> output = {};

      // Match each nutrient
      calibration.forEach((nutrient, levelsRaw) {
        Map<String, List<double>> levels = convertLevels(Map<String, dynamic>.from(levelsRaw));

        String level = imgService.matchLevel(
          sampleRGB,
          levels,
          threshold: 50,
        );

        output[nutrient] = level;
      });

      String n = output["Nitrogen"] ?? "LOW";
      String p = output["Phosphorus"] ?? "LOW";
      String k = output["Potassium"] ?? "LOW";

      int score = logic.score(n, p, k);
      String health = logic.healthLabel(score);
      List<String> rec = logic.recommendation(n, p, k);

      output["Soil Health"] = health;
      output["Score"] = score.toString();
      output["Advice"] = rec.join("\n");

      setState(() {
        results = output;
        analyzing = false;
      });
    } catch (e) {
      setState(() {
        results = {"Error": "Failed to analyze image: ${e.toString()}"};
        analyzing = false;
      });
    }
  }

  Map<String, List<double>> convertLevels(Map<String, dynamic> raw) {
    Map<String, List<double>> result = {};
    raw.forEach((key, value) {
      if (value is List) {
        result[key] = value.map((e) => (e as num).toDouble()).toList();
      }
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (analyzing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Analyzing soil sample, please wait..."),
            ],
          ),
        ),
      );
    }

    if (results == null || results!.containsKey("Error")) {
      return Scaffold(
        appBar: AppBar(title: Text("Soil Test Result")),
        body: Center(child: Text(results?["Error"] ?? "Unknown error")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Soil Test Result")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nutrient cards
            ...["Nitrogen", "Phosphorus", "Potassium"].map((nutrient) {
              String value = results![nutrient] ?? "UNKNOWN";
              Color color = value == "HIGH"
                  ? Colors.green
                  : value == "MEDIUM"
                  ? Colors.orange
                  : Colors.red;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(nutrient,
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      value,
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              );
            }).toList(),

            SizedBox(height: 20),
            Text("Soil Health",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Card(
              color: Colors.lightGreen[100],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  results!["Soil Health"] ?? "",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            SizedBox(height: 20),
            Text("Recommendation",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Card(
              color: Colors.yellow[100],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  results!["Advice"] ?? "",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.calculate_rounded, size: 16),
              label: const Text('Fertilizer Calculator'),
              onPressed: () {
                // Convert "HIGH" → "High" to match calculator's expected format
                String titleCase(String s) => s.isEmpty
                    ? s
                    : s[0].toUpperCase() + s.substring(1).toLowerCase();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FertilizerCalculatorScreen(
                      initialN: titleCase(results!['Nitrogen'] ?? 'Low'),
                      initialP: titleCase(results!['Phosphorus'] ?? 'Low'),
                      initialK: titleCase(results!['Potassium'] ?? 'Low'),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.bar_chart),
              label: Text("View NPK Dashboard"),
              onPressed: () {
                int convert(String level) {
                  switch (level) {
                    case "HIGH":
                      return 3;
                    case "MEDIUM":
                      return 2;
                    default:
                      return 1;
                  }
                }

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DashboardScreen(
                          convert(results!["Nitrogen"] ?? "LOW"),
                          convert(results!["Phosphorus"] ?? "LOW"),
                          convert(results!["Potassium"] ?? "LOW"),
                        )));
              },
            ),
          ],
        ),
      ),
    );
  }
}