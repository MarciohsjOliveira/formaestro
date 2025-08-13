
import 'package:flutter/material.dart';
import 'package:formaestro/formaestro.dart';

Future<String?> isEmailTaken(String value) async {
  // Simulate server-side check (replace with real API in production)
  await Future<void>.delayed(const Duration(milliseconds: 350));
  if (value.trim().endsWith('@taken.com')) {
    return 'Email already registered';
  }
  return null;
}

void main() {
  runApp(const MyApp());
}

/// Example app demonstrating Formaestro.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formaestro Demo',
      theme: ThemeData(useMaterial3: true),
      home: const SignUpPage(),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late final form = Formaestro(
    FormaestroSchema({
      'email': FieldX<String>(
        initialValue: '',
        validators: [
          Validators.required(),
          Validators.email(),
        ],
        asyncValidators: [
          isEmailTaken, // async availability check
        ],
      ),
      'password': FieldX<String>(
        initialValue: '',
        validators: [
          Validators.minLen(8),
        ],
      ),
      'confirm': FieldX<String>(initialValue: ''),
    }, rules: [
      Rule.cross(['password', 'confirm'], (values) {
        return values['password'] == values['confirm']
            ? null
            : 'Passwords mismatch';
      }),
    ]),
    debounce: const Duration(milliseconds: 250),
  );

  @override
  Widget build(BuildContext context) {
    final email = form.field<String>('email');
    final password = form.field<String>('password');
    final confirm = form.field<String>('confirm');

    return Scaffold(
      appBar: AppBar(title: const Text('Sign up with Formaestro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _TextField(
              label: 'Email',
              value: email.value,
              error: email.error,
              onChanged: (v) => setState(() => email.setValue(v)),
            ),
            _TextField(
              label: 'Password',
              obscure: true,
              value: password.value,
              error: password.error,
              onChanged: (v) => setState(() => password.setValue(v)),
            ),
            _TextField(
              label: 'Confirm password',
              obscure: true,
              value: confirm.value,
              error: confirm.error,
              onChanged: (v) => setState(() => confirm.setValue(v)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final ok = await form.validateAll();
                if (!mounted) return;
                final snack = SnackBar(
                  content: Text(ok ? 'All good!' : 'Please fix errors'),
                );
                ScaffoldMessenger.of(context).showSnackBar(snack);
              },
              child: const Text('Create account'),
            ),
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
