import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';
import 'auth_providers.dart';

class ConfirmEmailPage extends ConsumerStatefulWidget {
  const ConfirmEmailPage({super.key, this.userId, this.token});

  final String? userId;
  final String? token;

  @override
  ConsumerState<ConfirmEmailPage> createState() => _ConfirmEmailPageState();
}

class _ConfirmEmailPageState extends ConsumerState<ConfirmEmailPage> {
  bool _running = false;
  bool _confirmed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if ((widget.userId ?? '').isNotEmpty && (widget.token ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confirm());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Confirmar e-mail')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _confirmed ? Icons.mark_email_read_outlined : Icons.email_outlined,
                size: 56,
              ),
              const SizedBox(height: 18),
              Text(
                _confirmed
                    ? 'E-mail confirmado. Você já pode entrar.'
                    : _error ?? 'Confirme sua conta usando o link enviado por e-mail.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 18),
              if (_running) const Center(child: CircularProgressIndicator()),
              if (!_running && !_confirmed)
                FilledButton(
                  onPressed: _confirm,
                  child: const Text('Confirmar e-mail'),
                ),
              if (_confirmed)
                FilledButton(
                  onPressed: () => context.go('/auth'),
                  child: const Text('Ir para entrar'),
                ),
            ],
          ),
        ),
      );

  Future<void> _confirm() async {
    final userId = widget.userId;
    final token = widget.token;
    if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
      setState(() => _error = 'O link de confirmação está incompleto ou expirou.');
      return;
    }
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).confirmEmail(userId: userId, token: token);
      if (mounted) setState(() => _confirmed = true);
    } on AuthException catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível confirmar este link. Solicite um novo e-mail.');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }
}
