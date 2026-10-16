import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';
import 'auth_providers.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, this.userId, this.token});

  final String? userId;
  final String? token;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  late final TextEditingController _userId;
  late final TextEditingController _token;
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _userId = TextEditingController(text: widget.userId ?? '');
    _token = TextEditingController(text: widget.token ?? '');
  }

  @override
  void dispose() {
    _userId.dispose();
    _token.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Redefinir senha')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Escolha uma nova senha para a sua conta.'),
              const SizedBox(height: 16),
              TextField(
                controller: _userId,
                decoration: const InputDecoration(labelText: 'Identificador da conta'),
              ),
              TextField(
                controller: _token,
                decoration: const InputDecoration(labelText: 'Token de recuperação'),
              ),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
              ),
              TextField(
                controller: _confirmation,
                obscureText: true,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(labelText: 'Confirmar nova senha'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Salvando...' : 'Salvar nova senha'),
              ),
            ],
          ),
        ),
      );

  Future<void> _submit() async {
    if (_userId.text.trim().isEmpty || _token.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Use o link de recuperação completo e informe a nova senha.');
      return;
    }
    if (_password.text != _confirmation.text) {
      setState(() => _error = 'As senhas não conferem.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            userId: _userId.text.trim(),
            token: _token.text.trim(),
            password: _password.text,
          );
      if (mounted) context.go('/auth');
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
