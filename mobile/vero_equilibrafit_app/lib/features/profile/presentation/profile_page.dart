import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../../../shared/presentation/app_drawer.dart';
import '../../../core/offline/sync_conflicts_provider.dart';

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
}
