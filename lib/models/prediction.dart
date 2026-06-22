class Prediction {
  Prediction({required this.label, required this.confidence});

  final String label;
  final double confidence;

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
}
