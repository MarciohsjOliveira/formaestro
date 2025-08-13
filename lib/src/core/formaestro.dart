import 'dart:async';
import 'field_x.dart';
import 'rule.dart';

/// Orchestrates a form composed of multiple [FieldX] instances,
/// providing async-first validation, debouncing, and cross-field rules.
class Formaestro {
  /// Creates a [Formaestro] with a fixed [schema].
  ///
  /// The [debounce] controls how frequently [validateAll] fires when called
  /// repeatedly; useful to avoid spamming async validators.
  Formaestro(this.schema, {this.debounce = const Duration(milliseconds: 0)});

  /// Immutable schema describing the fields and rules.
  final FormaestroSchema schema;

  /// Debounce applied to [validateAll] calls.
  final Duration debounce;

  Timer? _debouncer;

  /// Map of field names to [FieldX] instances.
  Map<String, FieldX<dynamic>> get fields => schema.fields;

  /// Returns a typed field by [name].
  /// Throws [ArgumentError] if the field does not exist.
  FieldX<T> field<T>(String name) {
    final f = fields[name];
    if (f == null) throw ArgumentError('Field not found: $name');
    return f as FieldX<T>;
  }

  /// Current values snapshot.
  Map<String, dynamic> get values =>
      fields.map((k, v) => MapEntry(k, v.value));

  /// Validates all fields (sync + async) and cross-field rules.
  /// Returns `true` if the whole form is valid.
  Future<bool> validateAll() async {
    if (debounce.inMilliseconds > 0) {
      _debouncer?.cancel();
      final c = Completer<bool>();
      _debouncer = Timer(debounce, () async {
        c.complete(await _runValidation());
      });
      return c.future;
    }
    return _runValidation();
  }

  Future<bool> _runValidation() async {
    bool ok = true;
    // Per-field validation
    for (final f in fields.values) {
      final r = await f.validate();
      ok = ok && r;
    }
    // Cross-field rules
    for (final rule in schema.rules) {
      final msg = await rule.evaluate(values);
      if (msg != null) {
        // Attach error to the first field of the rule by convention.
        final names = schema.rulesFieldMap[rule];
        if (names != null && names.isNotEmpty) {
          final first = names.first;
          fields[first]?.setExternalError(msg);
        }
        ok = false;
      }
    }
    return ok;
  }

  /// Disposes underlying resources (e.g., field streams).
  void dispose() {
    for (final f in fields.values) {
      f.dispose();
    }
  }
}

/// Immutable schema describing the structure of a [Formaestro] form:
/// a map of named [FieldX] plus a set of cross-field [Rule]s.
class FormaestroSchema {
  FormaestroSchema(Map<String, FieldX<dynamic>> fields, {List<Rule>? rules})
      : fields = Map.unmodifiable(fields),
        rules = List.unmodifiable(rules ?? []) {
    for (final r in this.rules) {
      rulesFieldMap[r] = List.unmodifiable(r.fields);
    }
  }

  /// All fields in the schema keyed by name.
  final Map<String, FieldX<dynamic>> fields;

  /// Cross-field validation rules.
  final List<Rule> rules;

  /// Internal: associates each rule with the fields it depends on.
  final Map<Rule, List<String>> rulesFieldMap = {};
}
