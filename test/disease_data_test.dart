import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:multi_crop_disease_detector/services/disease_info_service.dart';

/// Guards the on-disk data contracts the app relies on: every model label
/// resolves to a disease entry, treatment coverage stays complete, and no
/// placeholder values leak into the UI.
void main() {
  const languages = ['en', 'bn', 'ur'];
  const treatmentSections = [
    'cultural_control',
    'chemical_control',
    'biological_control',
    'prevention_tips',
  ];

  late List<Map<String, dynamic>> diseases;
  late List<Map<String, dynamic>> treatments;
  late List<String> labelIds;

  setUpAll(() {
    diseases = _readJsonList('assets/data/disease_info.json');
    treatments = _readJsonList('assets/data/treatment_info.json');

    final labels = File('assets/labels/labels.txt')
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    labelIds = labels
        .map(DiseaseInfoService().resolveLabelIdForTesting)
        .toList(growable: false);
  });

  test('disease entries are unique and cover every model label', () {
    final ids = diseases.map((d) => d['id'] as String).toList();

    expect(ids.toSet(), hasLength(ids.length), reason: 'duplicate disease ids');

    final unknown = <String>[];
    for (var index = 0; index < labelIds.length; index++) {
      if (!ids.contains(labelIds[index])) {
        unknown.add('${labelIds[index]} (from "${_labels()[index]}")');
      }
    }

    expect(unknown, isEmpty, reason: 'labels without a disease entry');
  });

  test('every label resolves to a distinct disease id', () {
    expect(labelIds.toSet(), hasLength(labelIds.length));
  });

  test('severity values are localized-friendly tokens', () {
    const allowed = {'severe', 'moderate', 'mild', 'none', 'unknown'};

    for (final disease in diseases) {
      expect(
        allowed,
        contains(disease['severity']),
        reason: 'unexpected severity for ${disease['id']}',
      );
    }
  });

  test('no placeholder values leak into disease data', () {
    for (final disease in diseases) {
      final id = disease['id'] as String;
      for (final entry in disease.entries) {
        final value = entry.value;
        if (value is String) {
          expect(value.trim(), isNot('N/A'), reason: '$id.${entry.key}');
        } else if (value is List) {
          for (final item in value) {
            expect(item.toString().trim(), isNot('N/A'), reason: '$id.${entry.key}');
          }
        }
      }
    }
  });

  test('treatment data covers every disease except the invalid sentinel', () {
    final diseaseIds = diseases
        .map((d) => d['id'] as String)
        .where((id) => id != 'invalid')
        .toSet();
    final treatmentIds = treatments.map((t) => t['id'] as String).toSet();

    expect(treatmentIds, hasLength(treatments.length), reason: 'duplicates');
    expect(diseaseIds.difference(treatmentIds), isEmpty);
    expect(treatmentIds.difference(diseaseIds), isEmpty);
  });

  test('treatment entries are complete in all three languages', () {
    for (final treatment in treatments) {
      final id = treatment['id'] as String;
      final isHealthy = (treatment['id'] as String).endsWith('_healthy') ||
          id == 'healthy';

      for (final section in treatmentSections) {
        for (final language in languages) {
          final key = '${section}_$language';
          final value = treatment[key];

          expect(value, isA<List<dynamic>>(), reason: '$id.$key');

          final items = (value as List).whereType<String>().toList();
          if (isHealthy &&
              (section == 'chemical_control' ||
                  section == 'biological_control')) {
            expect(items, isEmpty, reason: '$id.$key should be empty');
          } else {
            expect(items, isNotEmpty, reason: '$id.$key is empty');
          }
          for (final item in items) {
            expect(item.trim(), isNotEmpty, reason: '$id.$key blank item');
          }
        }
      }
    }
  });

  test('chemically treated entries mention label compliance', () {
    for (final treatment in treatments) {
      final id = treatment['id'] as String;
      // Healthy entries carry monitoring advice only — no chemicals.
      if (id == 'healthy' || id.endsWith('_healthy')) {
        continue;
      }
      final combined = treatmentSections
          .map((section) => '${section}_en')
          .expand((key) => (treatment[key] as List).cast<String>())
          .join(' ')
          .toLowerCase();

      expect(
        combined,
        anyOf(contains('label'), contains('extension')),
        reason: '$id should reference label or extension guidance',
      );
    }
  });
}

List<Map<String, dynamic>> _readJsonList(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  return (decoded as List).whereType<Map<String, dynamic>>().toList();
}

List<String> _labels() => File('assets/labels/labels.txt')
    .readAsLinesSync()
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList(growable: false);
