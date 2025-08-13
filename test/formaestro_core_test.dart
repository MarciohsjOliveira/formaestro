import 'package:flutter_test/flutter_test.dart';
import 'package:formaestro/formaestro.dart';

void main() {
  test('sync validators and cross-field rule', () async {
    final form = Formaestro(
      FormaestroSchema({
        'email': FieldX<String>(initialValue: '', validators: [
          Validators.required(),
          Validators.email(),
        ]),
        'password': FieldX<String>(initialValue: '12345678'),
        'confirm': FieldX<String>(initialValue: '12345678'),
      }, rules: [
        Rule.cross(['password', 'confirm'], (values) {
          return values['password'] == values['confirm']
              ? null
              : 'Passwords mismatch';
        }),
      ]),
    );

    final ok = await form.validateAll();
    expect(ok, isFalse); // email required
    form.field<String>('email').setValue('john@example.com');
    final ok2 = await form.validateAll();
    expect(ok2, isTrue);
  });
}
