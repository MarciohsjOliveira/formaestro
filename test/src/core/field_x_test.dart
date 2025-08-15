import 'package:flutter_test/flutter_test.dart';
import 'package:formaestro/src/domain/field.dart';

void main() {
  // Ensure timers/streams behave properly in tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FieldX (streams & value updates)', () {
    test('emits new value at least once after setValue', () async {
      final f = FieldX<String>(initialValue: 'a');

      // Listen and assert that we eventually receive 'b', regardless of extra emissions.
      final nextB = f.valueStream.firstWhere((e) => e == 'b');

      f.setValue('b');

      expect(await nextB, 'b');
      expect(f.value, 'b');

      f.dispose();
    });

    test('valueStream is broadcast: multiple listeners receive the new value',
        () async {
      final f = FieldX<int>(initialValue: 0);

      // Independent subscriptions to the same broadcast stream.
      final a = f.valueStream.firstWhere((e) => e == 42);
      final b = f.valueStream.firstWhere((e) => e == 42);

      f.setValue(42);

      expect(await a, 42);
      expect(await b, 42);

      f.dispose();
    });

    test('after dispose, calling setValue does not produce further emissions',
        () async {
      final f = FieldX<String>(initialValue: 'x');

      // Capture any post-dispose emissions (there should be none).
      final received = <String>[];
      final sub = f.valueStream.listen(received.add);

      f.dispose();

      // Some implementations may throw, others may silently ignore.
      // Accept either behavior, but ensure no new events are emitted.
      try {
        f.setValue('y');
      } catch (_) {
        // ignore
      }

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(received, isEmpty,
          reason: 'No events should be emitted after dispose');

      await sub.cancel();
    });
  });
}
