import '../services/language_service.dart';

class DiseaseInfo {
  const DiseaseInfo({
    required this.id,
    required this.displayName,
    required this.crop,
    required this.diseaseName,
    required this.severity,
    required this.description,
    required this.symptoms,
    required this.culturalControl,
    required this.chemicalControl,
    required this.biologicalControl,
    required this.preventionTips,
    required this.favorableConditions,
    required this.spread,
  });

  final String id;
  final String displayName;
  final String crop;
  final String diseaseName;
  final String severity;
  final String description;
  final List<String> symptoms;
  final List<String> culturalControl;
  final List<String> chemicalControl;
  final List<String> biologicalControl;
  final List<String> preventionTips;
  final List<String> favorableConditions;
  final String spread;

  factory DiseaseInfo.fromJson(
    Map<String, dynamic> disease,
    Map<String, dynamic>? treatment,
    AppLanguage language,
  ) {
    final suffix = language.code;
    final crop = _localizedString(
      disease,
      'crop',
      suffix,
      fallback: 'Unknown crop',
    );
    final name = _localizedString(
      disease,
      'name',
      suffix,
      fallback: 'Unknown condition',
    );
    final culturalControl = _localizedStringList(
      treatment,
      'cultural_control',
      suffix,
    );
    final chemicalControl = _localizedStringList(
      treatment,
      'chemical_control',
      suffix,
    );
    final biologicalControl = _localizedStringList(
      treatment,
      'biological_control',
      suffix,
    );
    final preventionTips = _localizedStringList(
      treatment,
      'prevention_tips',
      suffix,
    );

    return DiseaseInfo(
      id: _string(disease['id']),
      displayName: crop == 'General' ? name : '$crop - $name',
      crop: crop,
      diseaseName: name,
      severity: _string(disease['severity'], fallback: 'unknown'),
      description: _localizedString(
        disease,
        'description',
        suffix,
        fallback: 'No disease information is available for this class yet.',
      ),
      symptoms: _localizedStringList(disease, 'symptoms', suffix),
      culturalControl: culturalControl,
      chemicalControl: chemicalControl,
      biologicalControl: biologicalControl,
      preventionTips:
          culturalControl.isEmpty &&
              chemicalControl.isEmpty &&
              biologicalControl.isEmpty &&
              preventionTips.isEmpty
          ? _genericRecommendations(language)
          : preventionTips,
      favorableConditions: _localizedStringList(
        disease,
        'favorable_conditions',
        suffix,
      ),
      spread: _localizedString(disease, 'spread', suffix),
    );
  }

  factory DiseaseInfo.fallback(
    String label, {
    AppLanguage language = AppLanguage.english,
  }) {
    final parts = label.split('___');
    final crop = parts.isNotEmpty
        ? parts.first.replaceAll('_', ' ')
        : 'Unknown crop';
    final disease = parts.length > 1
        ? parts.last.replaceAll('_', ' ')
        : label.replaceAll('_', ' ');

    return DiseaseInfo(
      id: _normalizeId(label),
      displayName: '$crop - $disease',
      crop: crop,
      diseaseName: disease,
      severity: disease.toLowerCase().contains('healthy') ? 'none' : 'unknown',
      description:
          'Detailed disease information is not available for this '
          'prediction yet.',
      symptoms: const [],
      culturalControl: const [],
      chemicalControl: const [],
      biologicalControl: const [],
      preventionTips: _genericRecommendations(language),
      favorableConditions: const [],
      spread: '',
    );
  }

  List<String> get recommendations {
    final recommendations = [
      ...culturalControl,
      ...chemicalControl,
      ...biologicalControl,
      ...preventionTips,
    ];

    if (recommendations.isNotEmpty) {
      return recommendations;
    }

    return const [];
  }

  static List<String> _genericRecommendations(AppLanguage language) {
    return switch (language) {
      AppLanguage.bangla => const [
        'পরিষ্কার ও পর্যাপ্ত আলোতে পাতার ছবি তুলুন।',
        'চিকিৎসার আগে মাঠের উপসর্গের সঙ্গে মিলিয়ে দেখুন।',
        'তীব্র সংক্রমণে স্থানীয় কৃষি বিশেষজ্ঞের পরামর্শ নিন।',
      ],
      AppLanguage.urdu => const [
        'صاف اور مناسب روشنی میں پتے کی تصویر لیں۔',
        'علاج سے پہلے کھیت کی علامات سے موازنہ کریں۔',
        'شدید انفیکشن کی صورت میں مقامی زرعی ماہر سے مشورہ کریں۔',
      ],
      AppLanguage.english => const [
        'Capture a clear, well-lit leaf image.',
        'Compare with symptoms in the field before treatment.',
        'Consult a local agriculture expert for severe infections.',
      ],
    };
  }

  static String _string(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String _localizedString(
    Map<String, dynamic>? source,
    String key,
    String suffix, {
    String fallback = '',
  }) {
    if (source == null) {
      return fallback;
    }

    return _string(
      source['${key}_$suffix'],
      fallback: _string(source['${key}_en'], fallback: fallback),
    );
  }

  static List<String> _localizedStringList(
    Map<String, dynamic>? source,
    String key,
    String suffix,
  ) {
    if (source == null) {
      return const [];
    }

    final localized = _stringList(source['${key}_$suffix']);
    if (localized.isNotEmpty) {
      return localized;
    }

    return _stringList(source['${key}_en']);
  }

  static String _normalizeId(String label) {
    return label
        .toLowerCase()
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll('___', '_')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
