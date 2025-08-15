// tool/coverage_check.dart
import 'dart:convert';
import 'dart:io';

Never fail(String msg) {
  stderr.writeln('ERROR: $msg');
  exit(1);
}

void main(List<String> args) async {
  final threshold =
      args.isNotEmpty ? double.tryParse(args.first) ?? 90.0 : 90.0;
  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    fail('coverage/lcov.info not found. Run "flutter test --coverage" first.');
  }

  bool isLibPath(String p) => p.startsWith('lib/') || p.contains('/lib/');

  final lines = const LineSplitter().convert(await lcovFile.readAsString());
  final totals = <String, int>{}; // DA total por arquivo
  final hits = <String, int>{}; // DA com exec>0 por arquivo
  String? current;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      final path = line.substring(3).trim();
      current = isLibPath(path) ? path : null;
      continue;
    }
    if (current == null) continue;
    if (line.startsWith('DA:')) {
      totals[current] = (totals[current] ?? 0) + 1;
      final parts = line.substring(3).split(',');
      final exec = int.tryParse(parts[1]) ?? 0;
      if (exec > 0) hits[current] = (hits[current] ?? 0) + 1;
    }
  }

  final total = totals.values.fold<int>(0, (a, b) => a + b);
  final hit = hits.values.fold<int>(0, (a, b) => a + b);
  final pct = total == 0 ? 0.0 : (hit * 100.0) / total;

  stdout.writeln(
    'Coverage (lib/): ${pct.toStringAsFixed(2)}% (hits=$hit total=$total) — threshold=$threshold%',
  );

  // Top 5 piores arquivos
  final perFile = totals.entries.map((e) {
    final t = e.value;
    final h = hits[e.key] ?? 0;
    final p = t == 0 ? 0.0 : (h * 100.0) / t;
    return MapEntry(e.key, p);
  }).toList()
    ..sort((a, b) => a.value.compareTo(b.value));

  stdout.writeln('Top 5 lowest-covered files under lib/:');
  for (final e in perFile.take(5)) {
    stdout.writeln('  - ${e.value.toStringAsFixed(2)}%\t${e.key}');
  }

  if (pct + 0.0001 < threshold) {
    fail(
        'Coverage below threshold (${pct.toStringAsFixed(2)}% < $threshold%).');
  }
}
