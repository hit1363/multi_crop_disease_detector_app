import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_record.dart';

class DatabaseService {
  DatabaseService._internal();

  factory DatabaseService() => _instance;

  static final DatabaseService _instance = DatabaseService._internal();

  static const String _storageKey = 'scan_history_records_v1';

  Future<int> insertScan(ScanRecord scan) async {
    final scans = await _loadScans();
    final nextId = scans.fold<int>(
          0,
          (largest, scan) => scan.id != null && scan.id! > largest
              ? scan.id!
              : largest,
        ) +
        1;

    final storedScan = scan.copyWith(id: nextId);
    scans.add(storedScan);
    await _saveScans(scans);
    return nextId;
  }

  Future<List<ScanRecord>> getAllScans() async {
    final scans = await _loadScans();
    scans.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return scans;
  }

  Future<int> deleteScan(int id) async {
    final scans = await _loadScans();
    final originalLength = scans.length;
    scans.removeWhere((scan) => scan.id == id);
    await _saveScans(scans);
    return originalLength - scans.length;
  }

  Future<void> close() async {}

  Future<List<ScanRecord>> _loadScans() async {
    final preferences = await SharedPreferences.getInstance();
    final storedValue = preferences.getString(_storageKey);
    if (storedValue == null || storedValue.isEmpty) {
      return [];
    }

    final decodedValue = jsonDecode(storedValue);
    if (decodedValue is! List) {
      return [];
    }

    return decodedValue
        .whereType<Map>()
        .map((item) => ScanRecord.fromMap(Map<String, Object?>.from(item)))
        .toList(growable: true);
  }

  Future<void> _saveScans(List<ScanRecord> scans) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode([for (final scan in scans) scan.toMap()]),
    );
  }
}
