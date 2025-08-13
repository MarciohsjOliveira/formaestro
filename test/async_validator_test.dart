import 'package:flutter_test/flutter_test.dart';
import 'package:formaestro/formaestro.dart';

Future<String?> isEmailTaken(String value) async {
  await Future<void>.delayed(const Duration(milliseconds: 5));
  return value.endsWith('@taken.com') ? 'Email already registered' : null;
}

void main() {
  test('async validator returns error for taken emails', () async {
    final form = Formaestro(
      FormaestroSchema({
        'email': FieldX<String>(
          initialValue: 'john@taken.com',
          validators: [Validators.email()],
          asyncValidators: [isEmailTaken],
        ),
      }),
    );

    final ok = await form.validateAll();
    expect(ok, isFalse);
    expect(form.field<String>('email').error, 'Email already registered');

    form.field<String>('email').setValue('john@ok.com');
    final ok2 = await form.validateAll();
    expect(ok2, isTrue);
  });
}
