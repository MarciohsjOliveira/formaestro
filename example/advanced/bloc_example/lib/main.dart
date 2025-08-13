import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formaestro/formaestro.dart';
import 'package:formaestro_bloc/formaestro_bloc.dart';

void main() => runApp(const BlocApp());

class BlocApp extends StatelessWidget {
  const BlocApp({super.key});

  @override
  Widget build(BuildContext context) {
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

    return MaterialApp(
      home: BlocProvider(
        create: (_) => FormaestroCubit(form),
        child: const BlocSignupPage(),
      ),
    );
  }
}

class BlocSignupPage extends StatelessWidget {
  const BlocSignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FormaestroCubit>();
    final form = cubit.formaestro;

    return Scaffold(
      appBar: AppBar(title: const Text('BLoC Example')),
      body: BlocBuilder<FormaestroCubit, FormaestroState>(
        builder: (context, state) {
          final email = form.field<String>('email');
          final password = form.field<String>('password');
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _TextField(
                  label: 'Email',
                  value: email.value,
                  error: email.error,
                  onChanged: email.setValue,
                ),
                _TextField(
                  label: 'Password',
                  obscure: true,
                  value: password.value,
                  error: password.error,
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
          );
        },
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
