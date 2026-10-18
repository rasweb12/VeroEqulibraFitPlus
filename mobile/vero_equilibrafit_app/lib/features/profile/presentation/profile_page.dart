import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../../../shared/presentation/app_drawer.dart';
import '../../../core/offline/sync_conflicts_provider.dart';
import '../../../core/persistence/owner_scope.dart';
import '../../../core/persistence/preferences_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final conflicts = ref.watch(syncConflictsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session?.displayName ?? session?.email ?? 'Conta',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (session?.displayName != null) Text(session!.email),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Metas nutricionais'),
                subtitle: const Text(
                  'Revise calorias e macronutrientes usados no diário.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/nutrition/goals'),
              ),
            ),
            const SizedBox(height: 12),
            conflicts.when(
              data: (items) => items.isEmpty
                  ? const SizedBox.shrink()
                  : Card(
                      child: ListTile(
                        leading: const Icon(Icons.sync_problem_outlined),
                        title: Text(
                          '${items.length} alteração(ões) precisa(m) de revisão',
                        ),
                        subtitle: const Text(
                          'Outra alteração foi registrada antes da sincronização. Seus dados locais foram preservados.',
                        ),
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const Text(
              'Questionário de saúde e objetivos será solicitado antes de recomendações personalizadas. Compartilhe somente o necessário e procure acompanhamento profissional para situações clínicas.',
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacidade e dados'),
                subtitle: const Text(
                  'Exporte os dados locais desta conta ou exclua sua conta pelo fluxo protegido.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: session == null
                    ? null
                    : () => _privacy(context, ref, session.userId),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => ref.read(authSessionProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Sair da conta'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _privacy(
    BuildContext context,
    WidgetRef ref,
    String ownerId,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Visualizar exportação local'),
                subtitle: const Text(
                  'Somente dados protegidos desta conta neste aparelho.',
                ),
                onTap: () async {
                  final store = ref.read(secureOwnerStoreProvider);
                  final data = <String, String?>{};
                  for (final key in ownerPrivateKeys(ownerId)) {
                    data[key.split(':').last] = await store.read(key);
                  }
                  if (!sheet.mounted) return;
                  Navigator.pop(sheet);
                  await showDialog<void>(
                    context: context,
                    builder: (dialog) => AlertDialog(
                      title: const Text('Dados locais'),
                      content: SingleChildScrollView(
                        child: SelectableText(data.toString()),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialog),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: Colors.red,
                ),
                title: const Text('Excluir conta'),
                subtitle: const Text(
                  'Remove a conta e os dados associados conforme a política do servidor.',
                ),
                onTap: () async {
                  Navigator.pop(sheet);
                  await ref.read(authSessionProvider.notifier).deleteAccount();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
