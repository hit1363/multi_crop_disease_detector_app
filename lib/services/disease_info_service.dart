import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/disease_info.dart';
import 'language_service.dart';

class DiseaseInfoService {
  DiseaseInfoService._internal();

  factory DiseaseInfoService() => _instance;

  static final DiseaseInfoService _instance = DiseaseInfoService._internal();

  static const String diseaseAssetPath = 'assets/data/disease_info.json';
  static const String treatmentAssetPath = 'assets/data/treatment_info.json';

  Map<String, Map<String, dynamic>>? _diseasesById;
  Map<String, Map<String, dynamic>>? _treatmentsById;

  Future<DiseaseInfo> findByPredictionLabel(
    String label, {
    AppLanguage language = AppLanguage.english,
  }) async {
    await _ensureLoaded();

    final id = _idFromLabel(label);
    final disease = _diseasesById![id];

    if (disease == null) {
      return DiseaseInfo.fallback(label, language: language);
    }

    return DiseaseInfo.fromJson(
      disease,
      _treatmentsById![disease['id']],
      language,
    );
  }

  Future<DiseaseInfo> findById(
    String id, {
    AppLanguage language = AppLanguage.english,
  }) async {
    await _ensureLoaded();
    final disease = _diseasesById![id];
    if (disease == null) {
      return DiseaseInfo.fallback(id, language: language);
    }
    return DiseaseInfo.fromJson(disease, _treatmentsById![id], language);
  }

  Future<List<DiseaseInfo>> getAllDiseases({
    AppLanguage language = AppLanguage.english,
  }) async {
    await _ensureLoaded();

    final diseases =
        _diseasesById!.values
            .map(
              (disease) => DiseaseInfo.fromJson(
                disease,
                _treatmentsById![disease['id']],
                language,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final cropComparison = a.crop.compareTo(b.crop);
            if (cropComparison != 0) {
              return cropComparison;
            }
            return a.diseaseName.compareTo(b.diseaseName);
          });

    return diseases;
  }

  Future<void> _ensureLoaded() async {
    if (_diseasesById != null) {
      return;
    }

    final diseaseData = jsonDecode(
      await rootBundle.loadString(diseaseAssetPath),
    );

    _diseasesById = {
      for (final item in diseaseData.whereType<Map<String, dynamic>>())
        if (item['id'] is String) item['id'] as String: item,
    };

    // Treatment data is optional: if the asset is missing or malformed the
    // app still shows disease info with generic recommendations rather than
    // crashing. A healthy seedling needs no treatment sections anyway.
    _treatmentsById = await _loadTreatments();
  }

  Future<Map<String, Map<String, dynamic>>> _loadTreatments() async {
    try {
      final treatmentData = jsonDecode(
        await rootBundle.loadString(treatmentAssetPath),
      );
      return {
        for (final item in treatmentData.whereType<Map<String, dynamic>>())
          if (item['disease_id'] is String)
            item['disease_id'] as String: item
          else if (item['id'] is String)
            item['id'] as String: item,
      };
    } catch (error) {
      assert(() {
        debugPrint('Treatment data unavailable: $error');
        return true;
      }());
      return const {};
    }
  }

  String _idFromLabel(String label) {
    final normalized = label
        .toLowerCase()
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll('___', '_')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return _labelAliases[normalized] ?? normalized;
  }

  /// Exposes label normalization so data tests can prove every model label
  /// resolves to a disease entry.
  @visibleForTesting
  String resolveLabelIdForTesting(String label) => _idFromLabel(label);

  static const Map<String, String> _labelAliases = {
    'apple_apple_scab': 'apple_scab',
    'corn_cercospora_leaf_spot_gray_leaf_spot': 'corn_cercospora_leaf_spot',
    'orange_haunglongbing': 'orange_citrus_greening',
    'pepper_bell_bacterial_spot': 'pepper_bacterial_spot',
    'pepper_bell_healthy': 'pepper_healthy',
    'tomato_spider_mites_two_spotted_spider_mite': 'tomato_spider_mites',
    'tomato_tomato_yellow_leaf_curl_virus': 'tomato_yellow_leaf_curl_virus',
  };
}
