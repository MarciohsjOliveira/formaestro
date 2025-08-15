import 'package:flutter_test/flutter_test.dart';
import 'package:formaestro/src/core/debouncer.dart';

void main() {
  // Ensures timers run properly in the test environment.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Debouncer', () {
    test('executes the action after the duration and not before', () async {
      var calls = 0;
      final d = Debouncer(const Duration(milliseconds: 50));

      d.run(() => calls++);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(calls, 0, reason: 'Should not run before the delay');

      await Future<void>.delayed(
          const Duration(milliseconds: 40)); // ≈70ms total
      expect(calls, 1, reason: 'Should run once after the delay');

      d.dispose();
    });

    test('reschedules if run() is called again before firing (last wins)',
        () async {
      var calls = 0;
      final d = Debouncer(const Duration(milliseconds: 50));

      d.run(() => calls++); // t=0 -> scheduled for t=50
      await Future<void>.delayed(const Duration(milliseconds: 25));
      d.run(() => calls++); // t=25 -> rescheduled for t=75

      await Future<void>.delayed(const Duration(milliseconds: 35)); // ~t=60
      expect(calls, 0, reason: 'Still before the latest scheduled time');

      await Future<void>.delayed(const Duration(milliseconds: 20)); // ~t=80
      expect(calls, 1, reason: 'Only the latest schedule should fire');

      d.dispose();
    });

    test('dispose() cancels any pending trigger', () async {
      var called = false;
      final d = Debouncer(const Duration(milliseconds: 50));

      d.run(() => called = true);
      d.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(called, isFalse,
          reason: 'Pending timer should be cancelled on dispose');
    });

    test('can be reused after it fires', () async {
      var calls = 0;
      final d = Debouncer(const Duration(milliseconds: 10));

      d.run(() => calls++);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls, 1);

      d.run(() => calls++);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls, 2);

      d.dispose();
    });

    test('multiple quick run() calls result in a single trigger', () async {
      var calls = 0;
      final d = Debouncer(const Duration(milliseconds: 30));

      d.run(() => calls++);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      d.run(() => calls++);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      d.run(() => calls++); // last schedule wins

      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(calls, 0, reason: 'Should not have fired yet');

      await Future<void>.delayed(
          const Duration(milliseconds: 15)); // ≈40ms after last schedule
      expect(calls, 1, reason: 'Should fire exactly once');

      d.dispose();
    });
  });
}
