import 'package:flutter/material.dart';
import 'package:formaestro/formaestro.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});
  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  late final FieldX<String> username;
  late final FieldX<String> password;
  late final FieldX<String> confirm;
  late final Formaestro form;

  @override
  void initState() {
    super.initState();
    String? required_(String v) => v.trim().isEmpty ? 'Required' : null;

    Future<String?> unique(String v) async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return v == 'taken' ? 'Already taken' : null;
    }

    username = FieldX<String>(
      initialValue: '',
      validators: [required_],
      asyncValidators: [unique],
      debounce: const Duration(milliseconds: 250),
    );

    password = FieldX<String>(
      initialValue: '',
      validators: [(v) => v.length < 8 ? 'Min 8 chars' : null],
    );

    confirm = FieldX<String>(initialValue: '');

    form = Formaestro(
      FormaestroSchema({
        'username': username,
        'password': password,
        'confirm': confirm,
      }, rules: [
        Rule.cross(['password', 'confirm'], (v) {
          return v['password'] == v['confirm']
              ? null
              : 'Passwords do not match';
        }),
      ]),
    );
  }

  @override
  void dispose() {
    form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('formaestro example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldXBuilder<String>(
                field: username,
                builder: (context, state) => TextField(
                  decoration: InputDecoration(
                    labelText: 'Username',
                    errorText: state.error,
                  ),
                  onChanged: (v) => username.setValue(v),
                ),
              ),
              const SizedBox(height: 12),
              FieldXBuilder<String>(
                field: password,
                builder: (context, state) => TextField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: state.error,
                  ),
                  obscureText: true,
                  onChanged: (v) => password.setValue(v),
                ),
              ),
              const SizedBox(height: 12),
              FieldXBuilder<String>(
                field: confirm,
                builder: (context, state) => TextField(
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    errorText: state.error,
                  ),
                  obscureText: true,
                  onChanged: (v) => confirm.setValue(v),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final ok = await form.validateAll();
                  final snackBar = SnackBar(
                    content: Text(ok ? 'Valid!' : 'Please fix errors'),
                  );
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                },
                child: const Text('Submit'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
