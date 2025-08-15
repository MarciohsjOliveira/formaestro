library;

import 'dart:async';

typedef Values = Map<String, dynamic>;

/// Cross-field rule interface
abstract interface class Rule {
  List<String> get keys;
  FutureOr<String?> call(Values values);

  factory Rule.cross(
          List<String> keys, FutureOr<String?> Function(Values v) fn) =>
      _CrossRule(keys, fn);
  factory Rule.crossAsync(
          List<String> keys, Future<String?> Function(Values v) fn) =>
      _CrossRule(keys, fn);
}

class _CrossRule implements Rule {
  _CrossRule(this.keys, this._fn);
  @override
  final List<String> keys;
  final FutureOr<String?> Function(Values values) _fn;
  @override
  FutureOr<String?> call(Values values) => _fn(values);
}

/// Schema registry. Store Object to avoid tight coupling/cycles.
class FormaestroSchema {
  final Map<String, Object> fields; // expects FieldX at runtime
  final List<Rule> rules;
  const FormaestroSchema(this.fields, {this.rules = const []});
}
