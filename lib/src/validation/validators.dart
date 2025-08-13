/// Built-in synchronous validators for convenience.
class Validators {
    /// Validates that a non-empty string is provided.
  static String? Function(String value) required({String message = 'Required'}) {
    return (v) => (v.trim().isEmpty) ? message : null;
  }

    /// Validates minimum length of [n] characters.
  static String? Function(String value) minLen(int n,
      {String message = 'Too short'}) {
    return (v) => v.length < n ? message : null;
  }

    /// Validates e-mail format using a simple regex.
  static String? Function(String value) email(
      {String message = 'Invalid email'}) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return (v) => regex.hasMatch(v) ? null : message;
  }
}
