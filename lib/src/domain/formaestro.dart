library;

import 'dart:async';
import 'package:formaestro/src/domain/contracts.dart';
import 'package:formaestro/src/domain/field.dart';

class Formaestro {
  Formaestro(
    this.schema, {
    this.debounce = const Duration(milliseconds: 300),
  });
  final FormaestroSchema schema;
  final Duration debounce;

  FieldX<T> field<T>(String key) {
    final f = schema.fields[key];
    if (f is! FieldX<T>) {
      throw ArgumentError('Field "$key" not found or wrong type');
    }
    return f;
  }

  Map<String, dynamic> get values => schema.fields.map((k, v) {
        final fx = v as FieldX<dynamic>;
        return MapEntry(k, fx.value);
      });

  Map<String, String?> get errors => schema.fields.map((k, v) {
        final fx = v as FieldX<dynamic>;
        return MapEntry(k, fx.error);
      });

  Future<bool> validateAll() async {
    for (final entry in schema.fields.entries) {
      final fx = entry.value as FieldX<dynamic>;
      fx.setValue(fx.value, validate: true);
    }
    for (final r in schema.rules) {
      final res = await r.call(values);
      if (res != null) return false;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return !errors.values.any((e) => e != null);
  }

  void dispose() {
    for (final f in schema.fields.values) {
      (f as FieldX).dispose();
    }
  }
}
