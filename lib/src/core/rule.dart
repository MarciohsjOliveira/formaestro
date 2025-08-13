
/// Async function that inspects the whole form [values] and,
/// if invalid, returns a message describing the issue.
typedef CrossFieldFn = Future<String?> Function(Map<String, dynamic> values);

/// Describes a cross-field rule; if `evaluate` returns a message,
/// the form is invalid and the message should be attached to a field.

/// Describes a cross-field rule. If [evaluate] returns a message,
/// the form is invalid and the error should be attached to one field.
class Rule {
  
  /// Creates a synchronous cross-field rule.
  Rule.cross(this.fields, String? Function(Map<String, dynamic>) fn)
      : _async = ((values) async => fn(values));

  
  /// Creates an asynchronous cross-field rule.
  Rule.crossAsync(this.fields, CrossFieldFn fn) : _async = fn;

    /// Field names that this rule depends on.
  final List<String> fields;
  final CrossFieldFn _async;

    /// Evaluates the rule against the current [values].
  Future<String?> evaluate(Map<String, dynamic> values) => _async(values);
}
