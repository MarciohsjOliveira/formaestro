import 'package:flutter_test/flutter_test.dart';
import 'package:formaestro/formaestro.dart';

void main() {
  test('cross-field rule attaches error to first field by convention', () async {
    final form = Formaestro(
      FormaestroSchema({
        'password': FieldX<String>(initialValue: '12345678'),
        'confirm': FieldX<String>(initialValue: 'xxxxx'),
      }, rules: [
        Rule.cross(['password', 'confirm'], (values) {
          return values['password'] == values['confirm'] ? null : 'Mismatch';
        }),
      ]),
    );

    final ok = await form.validateAll();
    expect(ok, isFalse);
    expect(form.field<String>('password').error, 'Mismatch');
  });
}
