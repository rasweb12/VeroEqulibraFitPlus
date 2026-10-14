import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Conta')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: session.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _form(context, error.toString()),
          data: (current) => current == null
              ? _form(context, null)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.email,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sua sessão é protegida no armazenamento seguro do dispositivo.',
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.read(authSessionProvider.notifier).logout(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, String? error) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _register ? 'Criar conta' : 'Entrar',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              error.replaceFirst('AuthException: ', ''),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_register)
          TextField(
            controller: _name,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Nome (opcional)'),
          ),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'E-mail'),
        ),
        TextField(
          controller: _password,
          obscureText: true,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(labelText: 'Senha'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Use ao menos 10 caracteres, com maiúscula, minúscula e número.',
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _submit,
          child: Text(_register ? 'Criar conta' : 'Entrar'),
        ),
        TextButton(
          onPressed: () => setState(() => _register = !_register),
          child: Text(_register ? 'Já tenho uma conta' : 'Criar uma conta'),
        ),
      ],
    ),
  );
  void _submit() {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) return;
    final controller = ref.read(authSessionProvider.notifier);
    _register
        ? controller.register(
            email,
            password,
            _name.text.trim().isEmpty ? null : _name.text.trim(),
          )
        : controller.login(email, password);
  }
}
