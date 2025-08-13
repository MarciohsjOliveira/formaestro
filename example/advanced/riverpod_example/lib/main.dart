import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formaestro/formaestro.dart';
import 'package:formaestro_riverpod/formaestro_riverpod.dart';

void main() => runApp(const ProviderScope(child: RiverpodApp()));

class RiverpodApp extends ConsumerWidget {
  const RiverpodApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = Formaestro(
      FormaestroSchema({
        'email': FieldX<String>(initialValue: '', validators: [
          Validators.required(),
          Validators.email(),
        ]),
        'password': FieldX<String>(initialValue: '', validators: [
          Validators.minLen(8),
        ]),
      }),
    );

    return ProviderScope(
      overrides: [
        formaestroProvider.overrideWithValue(form),
      ],
      child: MaterialApp(
        home: const RiverpodSignupPage(),
      ),
    );
  }
}

class RiverpodSignupPage extends ConsumerWidget {
  const RiverpodSignupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailErr$ = ref.watch(fieldErrorProvider('email'));
    final passwordErr$ = ref.watch(fieldErrorProvider('password'));

    final form = ref.read(formaestroProvider);
    final email = form.field<String>('email');
    final password = form.field<String>('password');

    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _TextField(
              label: 'Email',
              value: email.value,
              error: emailErr$.valueOrNull,
              onChanged: email.setValue,
            ),
            _TextField(
              label: 'Password',
              obscure: true,
              value: password.value,
              error: passwordErr$.valueOrNull,
              onChanged: password.setValue,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final ok = await form.validateAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'All good!' : 'Fix errors')),
                  );
                }
              },
              child: const Text('Submit'),
            )
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.error,
    this.obscure = false,
  });

  final String label;
  final String value;
  final bool obscure;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        onChanged: onChanged,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
