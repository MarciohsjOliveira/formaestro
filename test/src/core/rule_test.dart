import 'package:flutter_test/flutter_test.dart';
import 'package:formaestro/src/core/rule.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Rule', () {
    test('Rule.cross preserves fields and validates synchronously', () async {
      final rule = Rule.cross(['a', 'b'], (values) {
        return (values['a'] == values['b']) ? null : 'a != b';
      });

      expect(rule.fields, ['a', 'b']);

      final msg1 = await rule.evaluate({'a': 1, 'b': 2});
      expect(msg1, 'a != b');

      final msg2 = await rule.evaluate({'a': 7, 'b': 7});
      expect(msg2, isNull);
    });

    test(
        'Rule.crossAsync validates asynchronously and returns a message when invalid',
        () async {
      final taken = {'john@example.com', 'jane@example.com'};

      final rule = Rule.crossAsync(['email'], (values) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        final email = values['email'] as String?;
        if (email != null && taken.contains(email)) {
          return 'Email already taken';
        }
        return null;
      });

      expect(rule.fields, ['email']);

      final msg1 = await rule.evaluate({'email': 'john@example.com'});
      expect(msg1, 'Email already taken');

      final msg2 = await rule.evaluate({'email': 'new@example.com'});
      expect(msg2, isNull);
    });

    test('evaluate uses the latest values on each call', () async {
      final rule = Rule.crossAsync(['x', 'y', 'target'], (values) async {
        // Simulate a bit of latency
        await Future<void>.delayed(const Duration(milliseconds: 3));
        final sum = (values['x'] as int) + (values['y'] as int);
        return sum == values['target'] ? null : 'Sum mismatch';
      });

      // First call: invalid
      expect(
          await rule.evaluate({'x': 1, 'y': 2, 'target': 5}), 'Sum mismatch');

      // Second call: valid with new values
      expect(await rule.evaluate({'x': 2, 'y': 3, 'target': 5}), isNull);
    });
  });
}
