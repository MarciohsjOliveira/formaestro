import 'package:flutter_test/flutter_test.dart';
import 'package:formaestro/src/domain/contracts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Rule (contracts)', () {
    test('Rule.cross preserves keys and validates synchronously', () async {
      final rule = Rule.cross(['a', 'b'], (values) {
        return values['a'] == values['b'] ? null : 'a != b';
      });

      expect(rule.keys, ['a', 'b']);

      final msg1 = await rule({'a': 1, 'b': 2}); // sync branch
      expect(msg1, 'a != b');

      final msg2 = await rule({'a': 7, 'b': 7});
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

      expect(rule.keys, ['email']);

      final msg1 = await rule({'email': 'john@example.com'}); // async branch
      expect(msg1, 'Email already taken');

      final msg2 = await rule({'email': 'new@example.com'});
      expect(msg2, isNull);
    });

    test('Rule.crossAsync uses the latest values on each call', () async {
      // invalid if sum != target
      final rule = Rule.crossAsync(['x', 'y', 'target'], (values) async {
        await Future<void>.delayed(const Duration(milliseconds: 3));
        final sum = (values['x'] as int) + (values['y'] as int);
        return sum == values['target'] ? null : 'Sum mismatch';
      });

      expect(await rule({'x': 1, 'y': 2, 'target': 5}), 'Sum mismatch');
      expect(await rule({'x': 2, 'y': 3, 'target': 5}), isNull);
    });
  });

  group('FormaestroSchema', () {
    test('stores fields loosely (as Object) and rules list', () {
      final dummyA = Object();
      final dummyB = Object();

      final r = Rule.cross(['a', 'b'], (_) => null);
      final schema = FormaestroSchema({'a': dummyA, 'b': dummyB}, rules: [r]);

      expect(schema.fields.keys, containsAll(['a', 'b']));
      expect(schema.fields['a'], same(dummyA));
      expect(schema.fields['b'], same(dummyB));
      expect(schema.rules, hasLength(1));
      expect(schema.rules.first, same(r));
    });
  });
}
