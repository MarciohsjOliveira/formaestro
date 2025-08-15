import 'package:flutter_test/flutter_test.dart';
import 'package:formaestro/src/domain/contracts.dart';
import 'package:formaestro/src/domain/field.dart';
import 'package:formaestro/src/domain/formaestro.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Formaestro', () {
    test(
        'field<T> returns the typed field and throws on wrong type or unknown key',
        () {
      final age = FieldX<int>(initialValue: 21);
      final name = FieldX<String>(initialValue: 'Ana');

      final form = Formaestro(FormaestroSchema({
        'age': age,
        'name': name,
      }));

      // Correct types
      expect(form.field<int>('age'), same(age));
      expect(form.field<String>('name'), same(name));

      // Wrong type
      expect(() => form.field<String>('age'), throwsArgumentError);

      // Missing key
      expect(() => form.field<double>('missing'), throwsArgumentError);

      form.dispose();
    });

    test('values and errors reflect current field states (sync validation)',
        () async {
      String? required(String v) => v.trim().isEmpty ? 'required' : null;

      final email = FieldX<String>(initialValue: '', validators: [required]);
      final form = Formaestro(FormaestroSchema({'email': email}));

      // First run: empty -> sync error
      final ok1 = await form.validateAll();
      expect(ok1, isFalse);
      expect(form.values['email'], '');
      expect(form.errors['email'], 'required');

      // Fix and revalidate
      email.setValue('user@mail.com');
      final ok2 = await form.validateAll();
      expect(ok2, isTrue);
      expect(form.values['email'], 'user@mail.com');
      expect(form.errors['email'], isNull);

      form.dispose();
    });

    test(
        'validateAll runs async validators (with debounce) and applies cross-field rules',
        () async {
      // Async validator: fail when username == 'taken'
      Future<String?> uniqueUsername(String v) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return v == 'taken' ? 'already taken' : null;
      }

      final username = FieldX<String>(
        initialValue: 'taken',
        asyncValidators: [uniqueUsername],
        debounce: const Duration(milliseconds: 5),
      );
      final pass = FieldX<String>(initialValue: 'abc123');
      final confirm = FieldX<String>(initialValue: 'abc1234');

      final form = Formaestro(FormaestroSchema({
        'username': username,
        'pass': pass,
        'confirm': confirm,
      }, rules: [
        Rule.cross(['pass', 'confirm'], (values) {
          return values['pass'] == values['confirm']
              ? null
              : 'Passwords mismatch';
        }),
      ]));

      // Prepare a future that completes quando o erro "already taken" for emitido.
      final usernameErrorOnce =
          username.errorStream.firstWhere((e) => e == 'already taken');

      // 1) Deve falhar: username (async error) + cross-field mismatch.
      final ok1 = await form.validateAll();
      expect(ok1, isFalse);

      // Aguarde explicitamente até o erro de username ser emitido.
      expect(await usernameErrorOnce, 'already taken');

      // 2) Corrige username e confirm, e valida novamente.
      final usernameClearedOnce =
          username.errorStream.firstWhere((e) => e == null);
      username.setValue('new_user');
      confirm.setValue('abc123');

      final ok2 = await form.validateAll();
      expect(ok2, isTrue);

      // Aguarde a limpeza do erro antes de checar snapshot.
      await usernameClearedOnce;
      expect(form.errors['username'], isNull);
      expect(form.errors['pass'], isNull);
      expect(form.errors['confirm'], isNull);

      form.dispose();
    });

    test('values getter maps all fields (mixed types)', () async {
      final count = FieldX<int>(initialValue: 1);
      final flag = FieldX<bool>(initialValue: false);
      final name = FieldX<String>(initialValue: 'init');

      final form = Formaestro(FormaestroSchema({
        'count': count,
        'flag': flag,
        'name': name,
      }));

      // Update values and validate (no validators => should pass)
      count.setValue(7);
      flag.setValue(true);
      name.setValue('ok');
      final ok = await form.validateAll();

      expect(ok, isTrue);
      expect(form.values, {
        'count': 7,
        'flag': true,
        'name': 'ok',
      });
      expect(form.errors.values.where((e) => e != null), isEmpty);

      form.dispose();
    });
  });
}
