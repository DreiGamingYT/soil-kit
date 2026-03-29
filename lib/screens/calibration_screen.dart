import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/image_analysis_service.dart';
import '../services/calibration_service.dart';
import '../widgets/capture_box.dart';

class CalibrationScreen extends StatefulWidget {
  @override
  _CalibrationScreenState createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {

  CameraController? controller;
  List<CameraDescription>? cameras;

  String selectedNutrient = "Nitrogen";
  String selectedLevel = "LOW";

  final nutrients = ["Nitrogen", "Phosphorus", "Potassium", "pH"];
  final levels = ["LOW", "MEDIUM", "HIGH"];

  Map<String, dynamic> calibrationData = {};

  @override
  void initState() {
    super.initState();
    initCam();
  }

  Future initCam() async {
    cameras = await availableCameras();
    controller = CameraController(cameras![0], ResolutionPreset.medium);
    await controller!.initialize();
    setState(() {});
  }

  Future captureCalibration() async {
    if(controller == null || !controller!.value.isInitialized) return;

    final image = await controller!.takePicture();

    ImageAnalysisService imgService = ImageAnalysisService();
    // Automatically detect strip and get RGB
    List<double> rgb = await imgService.getAverageRGB(image.path);

    calibrationData.putIfAbsent(selectedNutrient, () => {});
    calibrationData[selectedNutrient][selectedLevel] = rgb;

    CalibrationService calService = CalibrationService();
    await calService.saveCalibration(calibrationData);

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$selectedNutrient - $selectedLevel Saved"))
    );
  }

  @override
  Widget build(BuildContext context) {

    if(controller == null || !controller!.value.isInitialized){
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Calibration")),
      body: Column(
        children: [

          DropdownButton(
            value: selectedNutrient,
            items: nutrients.map((n) =>
                DropdownMenuItem(value: n, child: Text(n))
            ).toList(),
            onChanged: (val){
              setState(() => selectedNutrient = val.toString());
            },
          ),

          DropdownButton(
            value: selectedLevel,
            items: levels.map((l) =>
                DropdownMenuItem(value: l, child: Text(l))
            ).toList(),
            onChanged: (val){
              setState(() => selectedLevel = val.toString());
            },
          ),

          Expanded(
            child: Stack(
              children: [
                CameraPreview(controller!),
                CaptureBox(),
              ],
            ),
          ),

          ElevatedButton(
            child: Text("Capture Calibration"),
            onPressed: captureCalibration,
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }
}