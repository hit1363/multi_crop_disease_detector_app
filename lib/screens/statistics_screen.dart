import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/scan_record.dart';
import '../services/database_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<List<ScanRecord>> _scansFuture;

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  void _loadScans() {
    _scansFuture = DatabaseService().getAllScans();
  }

  Future<void> _refreshScans() async {
    setState(_loadScans);
    await _scansFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics'), centerTitle: true),
      body: FutureBuilder<List<ScanRecord>>(
        future: _scansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load statistics.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final scans = snapshot.data ?? const <ScanRecord>[];
          if (scans.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No scan data yet. Run predictions to build statistics.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshScans,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TotalScansCard(totalScans: scans.length),
                const SizedBox(height: 16),
                _HealthBalanceCard(scans: scans),
                const SizedBox(height: 16),
                _CropDistributionCard(scans: scans),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TotalScansCard extends StatelessWidget {
  const _TotalScansCard({required this.totalScans});

  final int totalScans;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.analytics_outlined, size: 36),
            const SizedBox(width: 12),
            Text(
              'Total scans: $totalScans',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthBalanceCard extends StatelessWidget {
  const _HealthBalanceCard({required this.scans});

  final List<ScanRecord> scans;

  @override
  Widget build(BuildContext context) {
    final healthy = scans
        .where((scan) => scan.diseaseName.toLowerCase().contains('healthy'))
        .length;
    final diseased = scans.length - healthy;
    final healthyPercent = healthy / scans.length * 100;
    final diseasedPercent = diseased / scans.length * 100;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Healthy vs Disease',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: healthy.toDouble(),
                      title: '${healthyPercent.toStringAsFixed(0)}%',
                      color: colorScheme.primary,
                      radius: 72,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    PieChartSectionData(
                      value: diseased.toDouble(),
                      title: '${diseasedPercent.toStringAsFixed(0)}%',
                      color: Colors.redAccent,
                      radius: 72,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _LegendRow(
              color: colorScheme.primary,
              label: 'Healthy',
              value: '${healthyPercent.toStringAsFixed(1)}%',
            ),
            _LegendRow(
              color: Colors.redAccent,
              label: 'Disease',
              value: '${diseasedPercent.toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }
}

class _CropDistributionCard extends StatelessWidget {
  const _CropDistributionCard({required this.scans});

  final List<ScanRecord> scans;

  @override
  Widget build(BuildContext context) {
    final counts = _cropCounts(scans);
    final maxValue = counts.values.reduce((a, b) => a > b ? a : b).toDouble();
    final colorScheme = Theme.of(context).colorScheme;
    final entries = counts.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crop Scan Counts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxValue,
                  barGroups: [
                    for (var index = 0; index < entries.length; index++)
                      BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: entries[index].value.toDouble(),
                            color: colorScheme.primary,
                            width: 24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                  ],
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= entries.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              entries[index].key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in entries)
              _LegendRow(
                color: colorScheme.primary,
                label: entry.key,
                value: entry.value.toString(),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _cropCounts(List<ScanRecord> scans) {
    final counts = <String, int>{};
    for (final scan in scans) {
      counts.update(scan.cropName, (value) => value + 1, ifAbsent: () => 1);
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries.take(6));
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
}
