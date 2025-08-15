library;

import 'dart:async';
import 'package:formaestro/src/core/debouncer.dart';

/// Immutable snapshot for a field.
class FieldState<T> {
  final T value;
  final String? error;
  final bool isDirty;
  final bool isValidating;
  const FieldState({
    required this.value,
    this.error,
    this.isDirty = false,
    this.isValidating = false,
  });

  FieldState<T> copyWith(
      {T? value, String? error, bool? isDirty, bool? isValidating}) {
    return FieldState<T>(
      value: value ?? this.value,
      error: error,
      isDirty: isDirty ?? this.isDirty,
      isValidating: isValidating ?? this.isValidating,
    );
  }
}

class FieldX<T> {
  FieldX({
    required T initialValue,
    List<String? Function(T)> validators = const [],
    List<Future<String?> Function(T)> asyncValidators = const [],
    Duration? debounce,
  })  : _validators = validators,
        _asyncValidators = asyncValidators,
        _debouncer = Debouncer(debounce ?? const Duration()) {
    _state = FieldState<T>(value: initialValue);
  }

  final List<String? Function(T)> _validators;
  final List<Future<String?> Function(T)> _asyncValidators;
  final Debouncer _debouncer;

  late FieldState<T> _state;
  final _stateCtrl = StreamController<FieldState<T>>.broadcast();
  final _valueCtrl = StreamController<T>.broadcast();
  final _errorCtrl = StreamController<String?>.broadcast();

  bool _isDisposed = false;

  T get value => _state.value;
  String? get error => _state.error;

  Stream<FieldState<T>> get stateStream => _stateCtrl.stream;
  Stream<T> get valueStream => _valueCtrl.stream;
  Stream<String?> get errorStream => _errorCtrl.stream;

  void _emit() {
    if (_isDisposed) return; // guard after dispose
    try {
      _stateCtrl.add(_state);
      _valueCtrl.add(_state.value);
      _errorCtrl.add(_state.error);
    } on StateError {
      // Streams might already be closed if dispose() raced with a pending emission.
      // Swallow to keep disposal idempotent and safe under debounce timers.
    }
  }

  void setValue(T value, {bool validate = true}) {
    if (_isDisposed) return;
    _state = _state.copyWith(value: value, isDirty: true);
    _emit();
    if (validate) _runValidation();
  }

  void _runValidation() {
    if (_isDisposed) return;

    // Sync validators
    for (final v in _validators) {
      final err = v(_state.value);
      if (err != null) {
        _state = _state.copyWith(error: err);
        _emit();
        return;
      }
    }

    // No async validators
    if (_asyncValidators.isEmpty) {
      _state = _state.copyWith(error: null);
      _emit();
      return;
    }

    // Async path (debounced)
    _state = _state.copyWith(isValidating: true, error: null);
    _emit();

    _debouncer.run(() async {
      if (_isDisposed) return; // guard at timer fire

      for (final v in _asyncValidators) {
        final err = await v(_state.value);
        if (_isDisposed) return; // disposed while awaiting
        if (err != null) {
          _state = _state.copyWith(isValidating: false, error: err);
          _emit();
          return;
        }
      }

      _state = _state.copyWith(isValidating: false, error: null);
      _emit();
    });
  }

  bool get isValid => _state.error == null && !_state.isValidating;

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _debouncer.dispose(); // cancels any pending timer
    _stateCtrl.close();
    _valueCtrl.close();
    _errorCtrl.close();
  }
}
