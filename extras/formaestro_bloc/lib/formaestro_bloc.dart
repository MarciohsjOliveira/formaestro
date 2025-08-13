import 'package:bloc/bloc.dart';
import 'package:formaestro/formaestro.dart';

/// Immutable state with current values and per-field errors.
class FormaestroState {
  const FormaestroState({required this.values, required this.errors});
  final Map<String, dynamic> values;
  final Map<String, String?> errors;
}

class FormaestroCubit extends Cubit<FormaestroState> {
  FormaestroCubit(this.formaestro)
      : super(FormaestroState(values: formaestro.values, errors: {})) {
    // naive wiring: listen to each field's streams and emit
    for (final entry in formaestro.fields.entries) {
      // final name = entry.key; // name unused
      final field = entry.value;
      field.valueStream.listen((_) => _emit());
      field.errorStream.listen((_) => _emit());
    }
  }

  final Formaestro formaestro;

  void _emit() {
    final errs = <String, String?>{};
    for (final e in formaestro.fields.entries) {
      errs[e.key] = e.value.error;
    }
    emit(FormaestroState(values: formaestro.values, errors: errs));
  }
}
