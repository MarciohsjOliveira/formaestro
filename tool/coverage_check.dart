// tool/coverage_check.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

void fail(String msg) {
  stderr.writeln('ERROR: $msg');
  exit(1);
}

void main(List<String> args) async {
  final threshold =
      args.isNotEmpty ? double.tryParse(args.first) ?? 90.0 : 90.0;
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    fail('coverage/lcov.info not found. Run "flutter test --coverage" first.');
  }

  final lines = const LineSplitter().convert(await file.readAsString());

  // Aggregate only files under lib/ (both relative "lib/..." and absolute ".../lib/...")
  final totals = <String, int>{};
  final hits = <String, int>{};
  String? current;
  bool isLibPath(String p) => p.startsWith('lib/') || p.contains('/lib/');

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      final path = line.substring(3).trim();
      current = isLibPath(path) ? path : null;
    } else if (current != null && line.startsWith('DA:')) {
      totals[current] = (totals[current] ?? 0) + 1;
      final parts = line.substring(3).split(',');
      final exec = int.tryParse(parts[1]) ?? 0;
      if (exec > 0) hits[current] = (hits[current] ?? 0) + 1;
    }
  }

  final total = totals.values.fold<int>(0, (a, b) => a + b);
  final hit = hits.values.fold<int>(0, (a, b) => a + b);
  final pct = total == 0 ? 0.0 : (hit * 100.0) / total;

  if (kDebugMode) {
    if (kDebugMode) {
      print(
          'Coverage (lib/): ${pct.toStringAsFixed(2)}% (hits=$hit total=$total) — threshold=$threshold%');
    }
  }

  // Top 5 lowest-covered files under lib/
  final perFile = totals.map((f, t) {
    final h = hits[f] ?? 0;
    final p = t == 0 ? 0.0 : (h * 100.0) / t;
    return MapEntry(f, p);
  });
  final worst = perFile.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  if (kDebugMode) {
    print('Top 5 lowest-covered files under lib/:');
  }
  for (final e in worst.take(5)) {
    if (kDebugMode) {
      print('  - ${e.value.toStringAsFixed(2)}%\t${e.key}');
    }
  }

  if (pct + 0.0001 < threshold) {
    fail(
        'Coverage below threshold (${pct.toStringAsFixed(2)}% < $threshold%).');
  }
}
