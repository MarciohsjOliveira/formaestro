import 'package:flutter_test/flutter_test.dart';
import 'package:formaestro/src/domain/field.dart';

void main() {
  // Ensure timers/streams behave properly in tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FieldState', () {
    test('copyWith updates only provided properties', () {
      const a = FieldState<String>(value: 'v');
      final b = a.copyWith(error: 'oops', isDirty: true);

      expect(b.value, 'v');
      expect(b.error, 'oops');
      expect(b.isDirty, isTrue);
      expect(b.isValidating, isFalse);
    });
  });

  group('FieldX (streams & validation)', () {
    test('initial state uses initialValue and has no error', () {
      final f = FieldX<String>(initialValue: 'init');
      expect(f.value, 'init');
      expect(f.error, isNull);
      f.dispose();
    });

    test('setValue emits the new value (at least once)', () async {
      final f = FieldX<String>(initialValue: 'a');

      // Be tolerant with multiple emissions; assert we eventually see 'b'.
      final nextB = f.valueStream.firstWhere((e) => e == 'b');
      f.setValue('b');

      expect(await nextB, 'b');
      expect(f.value, 'b');

      f.dispose();
    });

    test(
        'sync validator failure sets error immediately; then clears when fixed',
        () async {
      String? mustBeLen2(String v) => v.length == 2 ? null : 'len != 2';

      final f = FieldX<String>(initialValue: '', validators: [mustBeLen2]);

      f.setValue('x'); // invalid
      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(f.error, 'len != 2');

      f.setValue('ok'); // valid
      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(f.error, isNull);

      f.dispose();
    });

    test(
        'async validator failure sets error after debounce; then clears when fixed',
        () async {
      Future<String?> asyncFailIfFoo(String v) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return v == 'foo' ? 'no foo' : null;
      }

      final f = FieldX<String>(
        initialValue: '',
        validators: const [],
        asyncValidators: [asyncFailIfFoo],
        debounce: const Duration(milliseconds: 5),
      );

      f.setValue('foo'); // should fail asynchronously
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(f.error, 'no foo');

      f.setValue('bar'); // should pass
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(f.error, isNull);

      f.dispose();
    });

    test('isValid reflects error/isValidating through async lifecycle',
        () async {
      Future<String?> asyncFailOnBad(String v) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return v == 'bad' ? 'bad!' : null;
      }

      final f = FieldX<String>(
        initialValue: 'ok',
        asyncValidators: [asyncFailOnBad],
        debounce: const Duration(milliseconds: 5),
      );

      // Trigger async validation with a failing value.
      f.setValue('bad');
      // Immediately after scheduling: validating => not valid.
      expect(f.isValid, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(f.error, 'bad!');
      expect(f.isValid, isFalse);

      // Fix it.
      f.setValue('good');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(f.error, isNull);
      expect(f.isValid, isTrue);

      f.dispose();
    });

    test('stateStream is broadcast and reflects isDirty/error changes',
        () async {
      String? nonEmpty(String v) => v.isEmpty ? 'required' : null;

      final f = FieldX<String>(initialValue: '', validators: [nonEmpty]);

      final statesA = <FieldState<String>>[];
      final statesB = <FieldState<String>>[];

      final subA = f.stateStream.listen(statesA.add);
      final subB = f.stateStream.listen(statesB.add);

      // Make it invalid, then valid
      f.setValue(''); // stays invalid (required)
      await Future<void>.delayed(const Duration(milliseconds: 1));
      f.setValue('x'); // becomes valid
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(statesA, isNotEmpty);
      expect(statesB, isNotEmpty);

      // Last snapshot should reflect the latest value and no error.
      final lastA = statesA.last;
      expect(lastA.value, 'x');
      expect(lastA.error, isNull);
      expect(lastA.isDirty, isTrue);

      await subA.cancel();
      await subB.cancel();
      f.dispose();
    });

    test('valueStream is broadcast: multiple listeners receive the new value',
        () async {
      final f = FieldX<int>(initialValue: 0);

      final a = f.valueStream.firstWhere((e) => e == 42);
      final b = f.valueStream.firstWhere((e) => e == 42);

      f.setValue(42);

      expect(await a, 42);
      expect(await b, 42);

      f.dispose();
    });

    test(
        'after dispose, setValue does not produce further emissions (may throw)',
        () async {
      final f = FieldX<String>(initialValue: 'x');

      final received = <String>[];
      final sub = f.valueStream.listen(received.add);

      f.dispose();

      // Some implementations may throw; accept either behavior but ensure no events.
      try {
        f.setValue('y');
      } catch (_) {
        // ignore
      }

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(received, isEmpty);

      await sub.cancel();
    });
  });
}
