import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formaestro/src/domain/field.dart';
import 'package:formaestro/src/flutter_adapters/field_builder.dart';

Widget _wrap(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

Widget _buildWith(FieldX<String> field) {
  return _wrap(
    FieldXBuilder<String>(
      field: field,
      builder: (context, state) => Column(
        children: [
          Text('v:${state.value}'),
          Text('e:${state.error ?? ''}'),
          Text('dirty:${state.isDirty}'),
          Text('validating:${state.isValidating}'),
        ],
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FieldXBuilder', () {
    testWidgets('renders initial state', (tester) async {
      final field = FieldX<String>(initialValue: 'init');
      await tester.pumpWidget(_buildWith(field));

      expect(find.text('v:init'), findsOneWidget);
      expect(find.text('e:'), findsOneWidget);
      expect(find.text('dirty:false'), findsOneWidget);
      expect(find.text('validating:false'), findsOneWidget);

      field.dispose();
    });

    testWidgets('rebuilds when value changes (sync)', (tester) async {
      final field = FieldX<String>(initialValue: 'a');
      await tester.pumpWidget(_buildWith(field));

      field.setValue('b');

      // Ensure the listener's setState runs before we assert
      await tester.pump(); // schedule frame
      await tester.pump(const Duration(milliseconds: 1)); // flush microtasks

      expect(find.text('v:b'), findsOneWidget);
      expect(find.text('dirty:true'), findsOneWidget);

      field.dispose();
    });

    testWidgets('shows sync validation error and clears when fixed',
        (tester) async {
      String? minLen2(String v) => v.length >= 2 ? null : 'len<2';
      final field = FieldX<String>(initialValue: '', validators: [minLen2]);

      await tester.pumpWidget(_buildWith(field));

      field.setValue('x'); // invalid
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('e:len<2'), findsOneWidget);

      field.setValue('ok'); // valid
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('e:'), findsOneWidget);

      field.dispose();
    });

    testWidgets('shows async validation error with debounce, then clears',
        (tester) async {
      Future<String?> unique(String v) async =>
          v == 'taken' ? 'already taken' : null;

      final field = FieldX<String>(
        initialValue: '',
        asyncValidators: [unique],
        debounce: const Duration(milliseconds: 5),
      );

      await tester.pumpWidget(_buildWith(field));

      field.setValue('taken');
      // debounce (5ms) + async future; give it enough time
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('e:already taken'), findsOneWidget);
      expect(find.text('validating:false'), findsOneWidget);

      field.setValue('free');
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('e:'), findsOneWidget);

      field.dispose();
    });

    testWidgets('no rebuilds after widget is removed from the tree',
        (tester) async {
      final field = FieldX<String>(initialValue: 'x');
      await tester.pumpWidget(_buildWith(field));
      expect(find.text('v:x'), findsOneWidget);

      // Remove the FieldXBuilder from the tree.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      // Emitting after disposal should not show old widgets
      field.setValue('y');
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.text('v:y'), findsNothing);

      field.dispose();
    });
  });
}
