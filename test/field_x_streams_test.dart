import 'package:flutter_test/flutter_test.dart';
import 'package:formaestro/formaestro.dart';

void main() {
  test('FieldX emits valueStream and errorStream appropriately', () async {
    final f = FieldX<String>(initialValue: '', validators: [
      Validators.required(),
    ]);

    final values = <String>[];
    final errors = <String?>[];

    final sub1 = f.valueStream.listen(values.add);
    final sub2 = f.errorStream.listen(errors.add);

    f.setValue('a');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(values.last, 'a');

    // validate should clear error when valid
    await f.validate();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(errors.isNotEmpty, true);
    expect(errors.last, isNull);

    // force external error and check stream
    f.setExternalError('Boom');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(errors.last, 'Boom');

    await sub1.cancel();
    await sub2.cancel();
    f.dispose();
  });
}
