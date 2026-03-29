class CalibrationData {
  Map<String, Map<String, List<double>>> nutrients;

  CalibrationData({required this.nutrients});

  factory CalibrationData.fromJson(Map<String, dynamic> json) {
    return CalibrationData(
      nutrients: json.map(
            (key, value) => MapEntry(
          key,
          Map<String, List<double>>.from(value.map(
                (k, v) => MapEntry(k, List<double>.from(v)),
          )),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() => nutrients;
}