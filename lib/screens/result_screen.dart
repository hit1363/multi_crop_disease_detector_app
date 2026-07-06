import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/disease_info.dart';
import '../models/prediction.dart';
import '../services/disease_info_service.dart';
import '../services/language_service.dart';
import '../services/report_service.dart';
import '../widgets/scan_image_view.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.imageBytes,
    this.imagePath,
    required this.predictions,
  });

  final Uint8List imageBytes;
  final String? imagePath;
  final List<Prediction> predictions;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  AppLanguage? _loadedLanguage;
  Future<DiseaseInfo>? _diseaseInfoFuture;
  bool _isExporting = false;

  Future<DiseaseInfo>? _futureForLanguage(AppLanguage language) {
    final topPrediction = widget.predictions.isEmpty
        ? null
        : widget.predictions.first;
    if (topPrediction == null) {
      return null;
    }

    if (_loadedLanguage != language || _diseaseInfoFuture == null) {
      _loadedLanguage = language;
      _diseaseInfoFuture = DiseaseInfoService().findByPredictionLabel(
        topPrediction.label,
        language: language,
      );
    }

    return _diseaseInfoFuture;
  }

  Future<void> _exportReport(Prediction prediction) async {
    if (_isExporting) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final englishInfo = await DiseaseInfoService().findByPredictionLabel(
        prediction.label,
        language: AppLanguage.english,
      );
      await ReportService().shareScanReport(
        imageBytes: widget.imageBytes,
        prediction: prediction,
        diseaseInfo: englishInfo,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export report: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPrediction = widget.predictions.isEmpty
        ? null
        : widget.predictions.first;
    final language = context.watch<LanguageService>().language;
    final diseaseInfoFuture = _futureForLanguage(language);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Information'),
        centerTitle: true,
      ),
      body: topPrediction == null
          ? const Center(child: Text('No predictions available.'))
          : FutureBuilder<DiseaseInfo>(
              future: diseaseInfoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to load disease information.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final diseaseInfo =
                    snapshot.data ?? DiseaseInfo.fallback(topPrediction.label);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ScanImageView(
                          imageBytes: widget.imageBytes,
                          imagePath: widget.imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SummaryCard(
                      prediction: topPrediction,
                      diseaseInfo: diseaseInfo,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _isExporting
                          ? null
                          : () => _exportReport(topPrediction),
                      icon: _isExporting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        _isExporting ? 'Preparing Report' : 'Export PDF Report',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StatusBanner(diseaseInfo: diseaseInfo),
                    const SizedBox(height: 16),
                    _PredictionList(predictions: widget.predictions),

                    const SizedBox(height: 16),
                    _InfoSection(
                      title: 'Description',
                      children: [diseaseInfo.description],
                    ),
                    _InfoSection(
                      title: 'Symptoms',
                      children: diseaseInfo.symptoms,
                    ),
                    _InfoSection(
                      title: 'Cultural Control',
                      children: diseaseInfo.culturalControl,
                    ),
                    _InfoSection(
                      title: 'Chemical Control',
                      children: diseaseInfo.chemicalControl,
                    ),
                    _InfoSection(
                      title: 'Biological Control',
                      children: diseaseInfo.biologicalControl,
                    ),
                    _InfoSection(
                      title: 'Favorable Conditions',
                      children: diseaseInfo.favorableConditions,
                    ),
                    if (diseaseInfo.spread.isNotEmpty)
                      _InfoSection(
                        title: 'Spread',
                        children: [diseaseInfo.spread],
                      ),
                    _InfoSection(
                      title: 'Recommendations',
                      children: diseaseInfo.recommendations,
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.prediction, required this.diseaseInfo});

  final Prediction prediction;
  final DiseaseInfo diseaseInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(diseaseInfo.displayName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.eco, size: 18),
                  label: Text(diseaseInfo.crop),
                ),
                Chip(
                  avatar: const Icon(Icons.speed, size: 18),
                  label: Text('Severity: ${diseaseInfo.severity}'),
                ),
                Chip(
                  backgroundColor: colorScheme.primaryContainer,
                  label: Text(
                    prediction.confidencePercent,
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictionList extends StatelessWidget {
  const _PredictionList({required this.predictions});

  final List<Prediction> predictions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top-3 Predictions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < predictions.length; index++)
              _PredictionTile(rank: index + 1, prediction: predictions[index]),
          ],
        ),
      ),
    );
  }
}

class _PredictionTile extends StatelessWidget {
  const _PredictionTile({required this.rank, required this.prediction});

  final int rank;
  final Prediction prediction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            child: Text('$rank'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prediction.label),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: prediction.confidence,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(prediction.confidencePercent),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.diseaseInfo});

  final DiseaseInfo diseaseInfo;

  @override
  Widget build(BuildContext context) {
    final severity = diseaseInfo.severity.toLowerCase();
    final (title, message, icon, color) = _bannerContent(severity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String title, String message, IconData icon, Color color) _bannerContent(
    String severity,
  ) {
    switch (severity) {
      case 'severe':
        return (
          'Severe Infection Detected',
          'Immediate action is recommended. The disease may spread rapidly and significantly reduce crop yield if left untreated.',
          Icons.error_outline,
          Colors.red,
        );
      case 'moderate':
        return (
          'Moderate Infection Detected',
          'The disease is present and should be managed soon to prevent further spread and damage.',
          Icons.warning_amber_rounded,
          Colors.orange,
        );
      case 'mild':
        return (
          'Mild Infection Detected',
          'Early signs of disease are visible. Monitor the plant closely and apply preventive measures if necessary.',
          Icons.info_outline,
          Colors.lightGreen,
        );
      case 'none':
        return (
          'Plant Appears Healthy',
          'No visible disease symptoms were detected. Continue regular monitoring and good crop management practices.',
          Icons.check_circle_outline,
          const Color.fromARGB(255, 25, 82, 27),
        );
      default:
        return (
          'Prediction Available',
          'Disease severity information is unavailable. Review symptoms carefully before taking action.',
          Icons.help_outline,
          Colors.grey,
        );
    }
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

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
