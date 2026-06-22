import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/disease_info.dart';
import '../services/disease_info_service.dart';
import '../services/language_service.dart';

class BrowseDiseasesScreen extends StatelessWidget {
  const BrowseDiseasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageService>().language;

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Diseases'), centerTitle: true),
      body: FutureBuilder<List<DiseaseInfo>>(
        future: DiseaseInfoService().getAllDiseases(language: language),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load disease encyclopedia.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final diseases = snapshot.data ?? const <DiseaseInfo>[];
          final groupedDiseases = _groupByCrop(diseases);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final entry in groupedDiseases.entries)
                Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.eco_outlined),
                    title: Text(entry.key),
                    subtitle: Text('${entry.value.length} conditions'),
                    children: [
                      for (final disease in entry.value)
                        ListTile(
                          title: Text(disease.diseaseName),
                          subtitle: Text(disease.severity),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    DiseaseDetailScreen(diseaseInfo: disease),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<DiseaseInfo>> _groupByCrop(List<DiseaseInfo> diseases) {
    final grouped = <String, List<DiseaseInfo>>{};
    for (final disease in diseases) {
      grouped.putIfAbsent(disease.crop, () => []).add(disease);
    }
    return grouped;
  }
}

class DiseaseDetailScreen extends StatelessWidget {
  const DiseaseDetailScreen({super.key, required this.diseaseInfo});

  final DiseaseInfo diseaseInfo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(diseaseInfo.diseaseName), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diseaseInfo.displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.grass, size: 18),
                        label: Text(diseaseInfo.crop),
                      ),
                      Chip(
                        avatar: const Icon(Icons.speed, size: 18),
                        label: Text('Severity: ${diseaseInfo.severity}'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _DiseaseInfoSection(
            title: 'Description',
            children: [diseaseInfo.description],
          ),
          _DiseaseInfoSection(
            title: 'Symptoms',
            children: diseaseInfo.symptoms,
          ),
          _DiseaseInfoSection(
            title: 'Favorable Conditions',
            children: diseaseInfo.favorableConditions,
          ),
          if (diseaseInfo.spread.isNotEmpty)
            _DiseaseInfoSection(
              title: 'Spread',
              children: [diseaseInfo.spread],
            ),
          _DiseaseInfoSection(
            title: 'Recommendations',
            children: diseaseInfo.recommendations,
          ),
        ],
      ),
    );
  }
}

class _DiseaseInfoSection extends StatelessWidget {
  const _DiseaseInfoSection({required this.title, required this.children});

  final String title;
  final List<String> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            for (final item in children)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(Icons.circle, size: 6),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
