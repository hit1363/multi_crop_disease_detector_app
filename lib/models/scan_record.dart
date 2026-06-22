class ScanRecord {
  const ScanRecord({
    this.id,
    required this.imagePath,
    required this.diseaseName,
    required this.confidence,
    required this.timestamp,
    required this.cropName,
  });

  final int? id;
  final String imagePath;
  final String diseaseName;
  final double confidence;
  final DateTime timestamp;
  final String cropName;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'disease_name': diseaseName,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'crop_name': cropName,
    };
  }

  factory ScanRecord.fromMap(Map<String, Object?> map) {
    return ScanRecord(
      id: map['id'] as int?,
      imagePath: map['image_path'] as String? ?? '',
      diseaseName: map['disease_name'] as String? ?? 'Unknown',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      timestamp:
          DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      cropName:
          map['crop_name'] as String? ??
          _cropFromDiseaseLabel(map['disease_name'] as String? ?? ''),
    );
  }

  ScanRecord copyWith({
    int? id,
    String? imagePath,
    String? diseaseName,
    double? confidence,
    DateTime? timestamp,
    String? cropName,
  }) {
    return ScanRecord(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      diseaseName: diseaseName ?? this.diseaseName,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      cropName: cropName ?? this.cropName,
    );
  }

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  static String _cropFromDiseaseLabel(String label) {
    if (label.contains('___')) {
      return label.split('___').first.replaceAll('_', ' ');
    }

    final firstWord = label.trim().split(RegExp(r'\s+')).firstOrNull;
    return firstWord == null || firstWord.isEmpty ? 'Unknown' : firstWord;
  }
}
