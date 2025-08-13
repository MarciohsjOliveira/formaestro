import 'dart:async';

/// Synchronous validator: returns an error message or `null` if valid.
typedef ValidatorSync<T> = String? Function(T value);
/// Asynchronous validator: returns an error message or `null` if valid.
typedef ValidatorAsync<T> = Future<String?> Function(T value);

/// Holds value, error and reactive streams for a single form field.
///
/// Each [FieldX] supports both synchronous and asynchronous validators.
class FieldX<T> {
  /// Creates a [FieldX] with an [initialValue].
  ///
  /// Provide [validators] for synchronous checks and [asyncValidators]
  /// for server-side or long-running validations.
  FieldX({
    required this.initialValue,
    List<ValidatorSync<T>>? validators,
    List<ValidatorAsync<T>>? asyncValidators,
  })  : _validators = validators ?? const [],
        _asyncValidators = asyncValidators ?? const [],
        _value = initialValue;

  /// Reactive streams
  final StreamController<T> _valueCtrl = StreamController<T>.broadcast();
  final StreamController<String?> _errorCtrl = StreamController<String?>.broadcast();

  /// Stream of value changes for reactive UIs.
  Stream<T> get valueStream => _valueCtrl.stream;

  /// Stream of error messages (`null` when valid).
  Stream<String?> get errorStream => _errorCtrl.stream;

  /// The initial value.
  final T initialValue;

  T _value;
  /// Whether the field has been focused/changed by the user.
  bool touched = false;
  /// Whether the value differs from [initialValue].
  bool dirty = false;
  /// Last validation error (`null` when valid).
  String? error;

  final List<ValidatorSync<T>> _validators;
  final List<ValidatorAsync<T>> _asyncValidators;

  /// Current field value.
  T get value => _value;

  /// Sets a new value and emits it to [valueStream].
  void setValue(T newValue) {
    if (newValue == _value) return;
    _value = newValue;
    dirty = true;
    _valueCtrl.add(_value);
  }

  /// Sets an external error (e.g., from cross-field rules) and emits to [errorStream].
  void setExternalError(String? message) {
    error = message;
    _errorCtrl.add(error);
  }

  /// Runs sync then async validations. Returns `true` if valid.
  Future<bool> validate() async {
    // Sync validators
    for (final v in _validators) {
      final msg = v(_value);
      if (msg != null) {
        error = msg;
        _errorCtrl.add(error);
        return false;
      }
    }
    // Async validators (first error wins)
    for (final v in _asyncValidators) {
      final msg = await v(_value);
      if (msg != null) {
        error = msg;
        _errorCtrl.add(error);
        return false;
      }
    }
    error = null;
    _errorCtrl.add(null);
    return true;
  }

  /// Dispose streams and free resources.
  void dispose() {
    _valueCtrl.close();
    _errorCtrl.close();
  }
}
