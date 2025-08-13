import 'package:flutter_test/flutter_test.dart';
import 'package:formaestro/formaestro.dart';

void main() {
  test('dispose closes field streams without throwing', () async {
    final form = Formaestro(
      FormaestroSchema({
        'a': FieldX<String>(initialValue: ''),
        'b': FieldX<int>(initialValue: 0),
      }),
    );

    // Call twice should not throw
    form.dispose();
    form.dispose();
  });
}
