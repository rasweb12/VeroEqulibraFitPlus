import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/app_drawer.dart';
import '../../../../shared/presentation/vero_design.dart';
import '../../../core/offline/sync_conflicts_provider.dart';
import '../../../core/persistence/owner_scope.dart';
import '../../../core/persistence/preferences_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../habits/presentation/habits_page.dart';
import '../../measurements/presentation/measurements_providers.dart';
import '../../nutrition/presentation/nutrition_goals_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final conflicts = ref.watch(syncConflictsProvider);
    final habits = ref.watch(habitsProvider);
    final measurements = ref.watch(measurementsProvider);
    final goals = ref.watch(nutritionGoalsProvider);
    final latestWeight = measurements.isEmpty
        ? null
        : measurements.first.weightKg;
    return Scaffold(
      drawer: const AppDrawer(),
      bottomNavigationBar: const VeroBottomNavigation(location: '/profile'),
      body: Builder(
        builder: (context) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            VeroTopBar(
              title: 'Perfil',
              onMenu: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xffF1F5F9)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: VeroColors.primary,
                    child: Text(
                      _initials(session?.displayName ?? session?.email ?? 'V'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session?.displayName ?? session?.email ?? 'Conta',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          session?.email ?? 'Sessão indisponível',
                          style: const TextStyle(color: VeroColors.muted),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: VeroColors.primary.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '• Conta autenticada',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: VeroColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xffF1F5F9)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                child: Row(
                  children: [
                    _metric(
                      'Peso atual',
                      latestWeight == null
                          ? 'Sem registro'
                          : '${latestWeight.toStringAsFixed(1)} kg',
                    ),
                    _metric(
                      'Meta diária',
                      goals.calories == 0
                          ? 'Não definida'
                          : '${goals.calories} kcal',
                    ),
                    _metric(
                      'Hidratação',
                      '${(habits.waterMl / 1000).toStringAsFixed(1)} L',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Metas e planejamento',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            VeroActionCard(
              icon: Icons.flag_outlined,
              title: 'Metas nutricionais',
              subtitle: 'Revise calorias e macronutrientes usados no diário.',
              tint: VeroColors.primary,
              onTap: () => context.push('/nutrition/goals'),
            ),
            const SizedBox(height: 12),
            VeroActionCard(
              icon: Icons.monitor_weight_outlined,
              title: 'Evolução corporal',
              subtitle: 'Consulte peso e medidas registrados.',
              tint: VeroColors.water,
              onTap: () => context.push('/measurements'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Preferências e conta',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 12),
            VeroActionCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacidade e dados',
              subtitle:
                  'Exporte os dados locais desta conta ou exclua sua conta pelo fluxo protegido.',
              tint: VeroColors.gemini,
              onTap: session == null
                  ? () {}
                  : () => _privacy(context, ref, session.userId),
            ),
            const SizedBox(height: 16),
            const Text(
              'Questionário de saúde e objetivos será solicitado antes de recomendações personalizadas. Compartilhe somente o necessário.',
              style: TextStyle(color: VeroColors.muted),
            ),
            const SizedBox(height: 20),
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

  Widget _metric(String label, String value) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: VeroColors.muted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );

  String _initials(String value) {
    final pieces = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (pieces.isEmpty) return 'V';
    return pieces.take(2).map((part) => part[0].toUpperCase()).join();
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
