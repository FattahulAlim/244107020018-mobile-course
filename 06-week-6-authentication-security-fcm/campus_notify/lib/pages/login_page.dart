import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../data/api_errors.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(authStateProvider.notifier);
    await notifier.login(_email.text.trim(), _password.text);

    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyMessage(state.error!))));
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Kata sandi'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: const Text('Masuk')),
          ],
        ),
      ),
    );
  }
}
