import 'dart:io';

import 'package:flutter/material.dart';

import '../models/scan_record.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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

  Future<void> _deleteScan(ScanRecord scan) async {
    final id = scan.id;
    if (id == null) {
      return;
    }

    await DatabaseService().deleteScan(id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Scan deleted')));
    setState(_loadScans);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan History'), centerTitle: true),
      body: FutureBuilder<List<ScanRecord>>(
        future: _scansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _HistoryMessage(
              icon: Icons.error_outline,
              title: 'Could not load history',
              message: '${snapshot.error}',
            );
          }

          final scans = snapshot.data ?? const <ScanRecord>[];
          if (scans.isEmpty) {
            return const _HistoryMessage(
              icon: Icons.history,
              title: 'No scans yet',
              message: 'Completed predictions will appear here.',
            );
          }

          final groupedScans = _groupByDate(scans);

          return RefreshIndicator(
            onRefresh: _refreshScans,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final entry in groupedScans.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final scan in entry.value)
                    _ScanHistoryTile(
                      scan: scan,
                      onDelete: () => _deleteScan(scan),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, List<ScanRecord>> _groupByDate(List<ScanRecord> scans) {
    final grouped = <String, List<ScanRecord>>{};
    for (final scan in scans) {
      grouped
          .putIfAbsent(_formatDateHeader(scan.timestamp), () => [])
          .add(scan);
    }
    return grouped;
  }

  String _formatDateHeader(DateTime timestamp) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${timestamp.day} ${months[timestamp.month - 1]} ${timestamp.year}';
  }
}

class _ScanHistoryTile extends StatelessWidget {
  const _ScanHistoryTile({required this.scan, required this.onDelete});

  final ScanRecord scan;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final imageFile = File(scan.imagePath);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.square(
            dimension: 64,
            child: imageFile.existsSync()
                ? Image.file(imageFile, fit: BoxFit.cover)
                : ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
          ),
        ),
        title: Text(
          _formatDiseaseName(scan.diseaseName),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${scan.cropName} crop'),
              Text(scan.confidencePercent),
              Text(_formatTime(scan.timestamp)),
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: 'Delete scan',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }

  static String _formatDiseaseName(String label) {
    return label.replaceAll('___', ' - ').replaceAll('_', ' ');
  }

  static String _formatTime(DateTime timestamp) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(timestamp.hour)}:${twoDigits(timestamp.minute)}';
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
