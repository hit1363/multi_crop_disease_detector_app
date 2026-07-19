import 'dart:convert';
import 'dart:typed_data';

class ScanRecord {
  const ScanRecord({
    this.id,
    required this.imagePath,
    this.imageBytesBase64,
    required this.diseaseName,
    this.diseaseId,
    required this.confidence,
    required this.timestamp,
    required this.cropName,
  });

  final int? id;
  final String imagePath;
  final String? imageBytesBase64;
  final String diseaseName;
  final String? diseaseId;
  final double confidence;
  final DateTime timestamp;
  final String cropName;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'image_bytes': imageBytesBase64,
      'disease_name': diseaseName,
      'disease_id': diseaseId,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'crop_name': cropName,
    };
  }

  factory ScanRecord.fromMap(Map<String, Object?> map) {
    return ScanRecord(
      id: map['id'] as int?,
      imagePath: map['image_path'] as String? ?? '',
      imageBytesBase64: map['image_bytes'] as String?,
      diseaseName: map['disease_name'] as String? ?? 'Unknown',
      diseaseId: map['disease_id'] as String?,
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
    String? imageBytesBase64,
    String? diseaseName,
    String? diseaseId,
    double? confidence,
    DateTime? timestamp,
    String? cropName,
  }) {
    return ScanRecord(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      imageBytesBase64: imageBytesBase64 ?? this.imageBytesBase64,
      diseaseName: diseaseName ?? this.diseaseName,
      diseaseId: diseaseId ?? this.diseaseId,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      cropName: cropName ?? this.cropName,
    );
  }

  Uint8List? get imageBytes {
    final encoded = imageBytesBase64;
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
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
