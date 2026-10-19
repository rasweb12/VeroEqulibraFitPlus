import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/vero_design.dart';
import '../data/auth_repository.dart';
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
  bool _passwordObscured = true;
  bool _confirmationRequested = false;
  bool _resendingConfirmation = false;
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: session.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 120),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _access(context, error.toString()),
                data: (current) => current == null
                    ? _access(context, null)
                    : _account(context, current),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _access(BuildContext context, String? error) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _hero(context),
      const SizedBox(height: 18),
      _formCard(context, error),
    ],
  );

  Widget _formCard(BuildContext context, String? error) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: VeroColors.border),
    ),
    child: _confirmationRequested
        ? _confirmation(context)
        : _form(context, error),
  );

  Widget _account(BuildContext context, AuthSession current) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _hero(context),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: VeroColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sessão ativa', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              current.email,
              style: const TextStyle(color: VeroColors.muted),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sua sessão é protegida no armazenamento seguro do dispositivo.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.read(authSessionProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Sair'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _confirmDeleteAccount(context),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Excluir minha conta'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    ],
  );
  Widget _hero(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: VeroColors.border),
    ),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: VeroColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.spa_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            children: const [
              TextSpan(text: 'VeroEquilibra'),
              TextSpan(
                text: 'Fit+',
                style: TextStyle(color: VeroColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Seu ritmo. Seus resultados.',
          style: TextStyle(color: VeroColors.muted),
        ),
      ],
    ),
  );

  Widget _confirmation(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(
        Icons.mark_email_read_outlined,
        size: 48,
        color: VeroColors.primary,
      ),
      const SizedBox(height: 12),
      Text(
        'Confirme seu e-mail',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'Enviamos um link de confirmação. Após confirmar, volte para entrar.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: _resendingConfirmation ? null : _resendConfirmation,
        icon: const Icon(Icons.refresh_rounded),
        label: Text(
          _resendingConfirmation ? 'Reenviando...' : 'Reenviar confirmação',
        ),
      ),
      TextButton(
        onPressed: () => setState(() {
          _confirmationRequested = false;
          _register = false;
        }),
        child: const Text('Voltar para entrar'),
      ),
    ],
  );

  Widget _form(BuildContext context, String? error) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_confirmationRequested) ...[
          const Icon(Icons.mark_email_read_outlined, size: 44),
          const SizedBox(height: 12),
          Text(
            'Confirme seu e-mail',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Enviamos um link de confirmação. Após confirmar, volte para entrar.',
          ),
          TextButton(
            onPressed: _resendingConfirmation ? null : _resendConfirmation,
            child: Text(
              _resendingConfirmation ? 'Reenviando...' : 'Reenviar confirmação',
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _confirmationRequested = false;
              _register = false;
            }),
            child: const Text('Voltar para entrar'),
          ),
        ] else ...[
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
            obscureText: _passwordObscured,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _passwordObscured ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(
                  _passwordObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _passwordObscured = !_passwordObscured),
              ),
            ),
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
          if (!_register)
            TextButton(
              onPressed: () => context.go('/forgot-password'),
              child: const Text('Esqueci minha senha'),
            ),
          TextButton(
            onPressed: () => setState(() => _register = !_register),
            child: Text(_register ? 'Já tenho uma conta' : 'Criar uma conta'),
          ),
        ],
      ],
    ),
  );
  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) return;
    final controller = ref.read(authSessionProvider.notifier);
    if (_register) {
      try {
        await controller.register(
          email,
          password,
          _name.text.trim().isEmpty ? null : _name.text.trim(),
        );
        if (mounted) setState(() => _confirmationRequested = true);
      } on AuthException {
        // The provider state already displays the safe server message.
      }
      return;
    }
    await controller.login(email, password);
  }

  Future<void> _resendConfirmation() async {
    setState(() => _resendingConfirmation = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resendEmailConfirmation(_email.text);
    } on AuthException {
      // Reuse the same non-enumerating UI message for any send result.
    } finally {
      if (mounted) setState(() => _resendingConfirmation = false);
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Essa ação exclui sua conta e remove os dados locais desta conta deste aparelho. Ela não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir conta'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(authSessionProvider.notifier).deleteAccount();
    } on AuthException {
      // The provider retains a safe error state for the form.
    }
  }
}
