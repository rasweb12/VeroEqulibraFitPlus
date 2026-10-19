import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/training/presentation/training_providers.dart';
import 'features/training/domain/planned_exercise.dart';
import 'features/training/domain/exercise.dart';
import 'features/training/presentation/exercise_demo_player.dart';
import 'features/dashboard/presentation/dashboard_page.dart';
import 'features/habits/presentation/habits_page.dart';
import 'features/habits/presentation/missions_page.dart';
import 'features/nutrition/presentation/nutrition_page.dart';
import 'features/nutrition/presentation/nutrition_reports_page.dart';
import 'features/coach/presentation/coach_page.dart';
import 'features/measurements/presentation/measurements_page.dart';
import 'features/auth/presentation/auth_page.dart';
import 'features/auth/presentation/auth_splash_page.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/forgot_password_page.dart';
import 'features/auth/presentation/reset_password_page.dart';
import 'features/auth/presentation/confirm_email_page.dart';
import 'features/nutrition/presentation/nutrition_plans_page.dart';
import 'features/nutrition/presentation/nutrition_providers.dart';
import 'features/nutrition/presentation/nutrition_goals_page.dart';
import 'features/nutrition/presentation/barcode_scanner_page.dart';
import 'features/profile/presentation/profile_page.dart';
import 'features/training/domain/training_plan.dart';
import 'features/training/presentation/workout_session_page.dart';
import 'features/training/presentation/workout_history_page.dart';
import 'features/training/presentation/training_progress_page.dart';
import 'features/training/presentation/workout_history_detail_page.dart';
import 'core/offline/sync_providers.dart';
import 'shared/presentation/vero_design.dart';

class VeroEqulibraFitApp extends ConsumerWidget {
  const VeroEqulibraFitApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authSessionProvider);
    ref.listen(authSessionProvider, (previous, next) {
      final session = next.valueOrNull;
      if (session != null) {
        unawaited(_synchronize(ref, session));
      }
    });
    final router = GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        if (state.uri.scheme == 'veroequilibrafit' &&
            state.uri.host == 'account' &&
            (state.uri.path == '/confirm-email' ||
                state.uri.path == '/reset-password')) {
          return '${state.uri.path}?${state.uri.query}';
        }
        final atSplash = state.matchedLocation == '/splash';
        final atAuth = state.matchedLocation == '/auth';
        final atForgotPassword = state.matchedLocation == '/forgot-password';
        final atResetPassword = state.matchedLocation == '/reset-password';
        final atConfirmEmail = state.matchedLocation == '/confirm-email';
        if (auth.isLoading) {
          return atSplash ? null : '/splash';
        }
        final session = auth.valueOrNull;
        if (session == null) {
          return (atAuth ||
                  atForgotPassword ||
                  atResetPassword ||
                  atConfirmEmail)
              ? null
              : '/auth?returnTo=${Uri.encodeComponent(state.uri.toString())}';
        }
        if (atSplash ||
            atAuth ||
            atForgotPassword ||
            atResetPassword ||
            atConfirmEmail) {
          return state.uri.queryParameters['returnTo'] ?? '/';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const AuthSplashPage(),
        ),
        GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => ResetPasswordPage(
            userId: state.uri.queryParameters['userId'],
            token: state.uri.queryParameters['token'],
          ),
        ),
        GoRoute(
          path: '/confirm-email',
          builder: (context, state) => ConfirmEmailPage(
            userId: state.uri.queryParameters['userId'],
            token: state.uri.queryParameters['token'],
          ),
        ),
        ..._privateRoutes,
      ],
    );
    return MaterialApp.router(
      title: 'VeroEqulibraFit+',
      theme: veroTheme(Brightness.light),
      darkTheme: veroTheme(Brightness.dark),
      routerConfig: router,
    );
  }

  static Future<void> _synchronize(WidgetRef ref, AuthSession session) async {
    final service = ref.read(syncServiceProvider);
    await service.pushPending(session);
    await service.pullRemote(session);
    ref.invalidate(plansProvider);
    ref.invalidate(mealsProvider);
  }

  static final _privateRoutes = <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const DashboardPage()),
    GoRoute(path: '/training', builder: (context, state) => const PlansPage()),
    GoRoute(
      path: '/training/progress',
      builder: (context, state) => const TrainingProgressPage(),
    ),
    GoRoute(
      path: '/training/history',
      builder: (context, state) => const WorkoutHistoryPage(),
    ),
    GoRoute(
      path: '/training/history/:sessionId',
      builder: (context, state) => WorkoutHistoryDetailPage(
        sessionId: state.pathParameters['sessionId']!,
      ),
    ),
    GoRoute(
      path: '/training/:planId/start',
      builder: (context, state) =>
          WorkoutSessionPage(planId: state.pathParameters['planId']!),
    ),
    GoRoute(
      path: '/training/:planId',
      builder: (context, state) =>
          TrainingPlanPage(planId: state.pathParameters['planId']!),
    ),
    GoRoute(
      path: '/training/:planId/exercise/:exerciseId',
      builder: (context, state) => TrainingExerciseConfigPage(
        planId: state.pathParameters['planId']!,
        exerciseId: state.pathParameters['exerciseId']!,
      ),
    ),
    GoRoute(
      path: '/exercises',
      builder: (context, state) => const ExerciseLibraryPage(),
    ),
    GoRoute(
      path: '/training/:planId/exercises',
      builder: (context, state) =>
          ExerciseLibraryPage(planId: state.pathParameters['planId']),
    ),
    GoRoute(path: '/habits', builder: (context, state) => const HabitsPage()),
    GoRoute(
      path: '/missions',
      builder: (context, state) => const MissionsPage(),
    ),
    GoRoute(
      path: '/nutrition',
      builder: (context, state) => const NutritionPage(),
    ),
    GoRoute(
      path: '/nutrition/reports',
      builder: (context, state) => const NutritionReportsPage(),
    ),
    GoRoute(
      path: '/nutrition/new',
      builder: (context, state) => NutritionMealFormPage(
        barcode: state.uri.queryParameters['barcode'],
        initialName: state.uri.queryParameters['name'],
        initialCalories: double.tryParse(
          state.uri.queryParameters['calories'] ?? '',
        ),
        initialProtein: double.tryParse(
          state.uri.queryParameters['protein'] ?? '',
        ),
        initialCarbs: double.tryParse(state.uri.queryParameters['carbs'] ?? ''),
        initialFat: double.tryParse(state.uri.queryParameters['fat'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/nutrition/photo-review',
      builder: (context, state) {
        final input = state.extra;
        if (input is! PhotoMealReviewInput) {
          return const NutritionPage();
        }
        return NutritionPhotoReviewPage(input: input);
      },
    ),
    GoRoute(
      path: '/nutrition/:mealId/edit',
      builder: (context, state) =>
          NutritionMealFormPage(mealId: state.pathParameters['mealId']),
    ),
    GoRoute(
      path: '/nutrition/plans',
      builder: (context, state) => const NutritionPlansPage(),
    ),
    GoRoute(
      path: '/nutrition/goals',
      builder: (context, state) => const NutritionGoalsPage(),
    ),
    GoRoute(
      path: '/nutrition/barcode',
      builder: (context, state) => const BarcodeScannerPage(),
    ),
    GoRoute(path: '/coach', builder: (context, state) => const CoachPage()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
    GoRoute(
      path: '/measurements',
      builder: (context, state) => const MeasurementsPage(),
    ),
  ];
}

final trainingArchiveTabProvider = StateProvider<bool>((ref) => false);

class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePlans = ref.watch(plansProvider);
    final archivedPlans = ref.read(plansProvider.notifier).archivedPlans;
    final showingArchived = ref.watch(trainingArchiveTabProvider);
    final plans = showingArchived ? archivedPlans : activePlans;

    // VERO_765A_START — Somente interface; ações existentes preservadas.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus treinos'),
        actions: [
          IconButton(
            tooltip: 'Biblioteca de exercícios',
            onPressed: () => context.go('/exercises'),
            icon: const Icon(Icons.fitness_center_outlined),
          ),
          IconButton(
            tooltip: 'Dashboard',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.dashboard_outlined),
          ),
          IconButton(
            tooltip: 'Conta',
            onPressed: () => context.go('/auth'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      floatingActionButton: showingArchived
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _createPlan(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nova ficha'),
            ),
      bottomNavigationBar: const VeroBottomNavigation(location: '/training'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          Text(
            'Seu planejamento',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          const Text(
            'Organize suas fichas e acompanhe os resultados.',
            style: TextStyle(color: VeroColors.muted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _trainingShortcut(
                  context,
                  icon: Icons.history_rounded,
                  title: 'Histórico',
                  subtitle: 'Treinos concluídos',
                  onTap: () => context.go('/training/history'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _trainingShortcut(
                  context,
                  icon: Icons.insights_outlined,
                  title: 'Minha evolução',
                  subtitle: 'Resultados e recordes',
                  onTap: () => context.go('/training/progress'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fichas de treino',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${activePlans.length} ativas',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('Ativas (${activePlans.length})'),
                selected: !showingArchived,
                onSelected: (_) =>
                    ref.read(trainingArchiveTabProvider.notifier).state = false,
              ),
              ChoiceChip(
                label: Text('Arquivadas (${archivedPlans.length})'),
                selected: showingArchived,
                onSelected: (_) =>
                    ref.read(trainingArchiveTabProvider.notifier).state = true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (plans.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 24,
                ),
                child: Column(
                  children: [
                    Icon(
                      showingArchived
                          ? Icons.archive_outlined
                          : Icons.fitness_center_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      showingArchived
                          ? 'Nenhuma ficha arquivada.'
                          : 'Nenhuma ficha ativa. Crie uma ficha para começar.',
                      textAlign: TextAlign.center,
                    ),
                    if (!showingArchived) ...[
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () => _createPlan(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Criar primeira ficha'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          for (final plan in plans)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: .12),
                          child: Icon(
                            Icons.fitness_center,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            plan.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Opções da ficha',
                          onSelected: (action) =>
                              _action(context, ref, plan.id, action),
                          itemBuilder: (_) => [
                            if (!showingArchived) ...[
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar ficha'),
                              ),
                              const PopupMenuItem(
                                value: 'duplicate',
                                child: Text('Duplicar ficha'),
                              ),
                              const PopupMenuItem(
                                value: 'archive',
                                child: Text('Arquivar ficha'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Excluir ficha'),
                              ),
                            ] else
                              const PopupMenuItem(
                                value: 'unarchive',
                                child: Text('Restaurar ficha'),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      plan.objective,
                      style: const TextStyle(color: VeroColors.muted),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.list_alt, size: 16),
                          label: Text('${plan.exercises.length} exercícios'),
                        ),
                        if (plan.weekdays.isNotEmpty)
                          Chip(
                            avatar: const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                            ),
                            label: Text(
                              plan.weekdays.map(_weekdayLabel).join(', '),
                            ),
                          ),
                      ],
                    ),
                    if (!showingArchived) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: plan.exercises.isEmpty
                              ? null
                              : () => context.go('/training/${plan.id}/start'),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Iniciar treino'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/training/${plan.id}'),
                          icon: const Icon(Icons.tune_outlined),
                          label: const Text('Abrir / configurar ficha'),
                        ),
                      ),
                    ] else
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Ficha arquivada — restaure para iniciar.'),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _trainingShortcut(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 26,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
  // VERO_765A_END

  Future<void> _action(
    BuildContext context,
    WidgetRef ref,
    String id,
    String action,
  ) async {
    final controller = ref.read(plansProvider.notifier);
    if (action == 'edit') {
      final plan = ref
          .read(plansProvider)
          .where((item) => item.id == id)
          .firstOrNull;

      if (plan != null) {
        await _editPlan(context, ref, plan);
      }
      return;
    }
    if (action == 'duplicate') {
      controller.duplicate(id);
      return;
    }
    if (action == 'archive') {
      controller.archive(id);
      return;
    }
    if (action == 'unarchive') {
      controller.unarchive(id);
      return;
    }
    if (action != 'delete') return;

    final plan = ref
        .read(plansProvider)
        .where((item) => item.id == id)
        .firstOrNull;
    if (plan == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir ficha?'),
        content: Text('“${plan.name}” será removida da lista.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir ficha'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      controller.delete(id);
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            content: Text('Ficha excluída.'),
          ),
        );
    }
  }

  Future<void> _editPlan(
    BuildContext context,
    WidgetRef ref,
    TrainingPlan plan,
  ) async {
    String name = plan.name;
    String objective = plan.objective;
    final weekdays = plan.weekdays.toSet();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar ficha de treino'),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: plan.name,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nome da ficha',
                      ),
                      onChanged: (value) {
                        name = value;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      initialValue: plan.objective,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Objetivo'),
                      onChanged: (value) {
                        objective = value;
                      },
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Dias da semana',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(7, (day) {
                        return FilterChip(
                          label: Text(_weekdayLabel(day)),
                          selected: weekdays.contains(day),
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                weekdays.add(day);
                              } else {
                                weekdays.remove(day);
                              }
                            });
                          },
                        );
                      }),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      '${plan.exercises.length} exercícios '
                      'serão preservados.',
                      style: const TextStyle(
                        color: VeroColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancelar'),
                ),

                FilledButton.icon(
                  onPressed: () {
                    if (name.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Informe o nome da ficha.'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(true);
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar alterações'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || !context.mounted) {
      return;
    }

    ref
        .read(plansProvider.notifier)
        .updatePlanDetails(
          id: plan.id,
          name: name,
          objective: objective,
          weekdays: weekdays.toList()..sort(),
        );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Ficha atualizada com sucesso.'),
          duration: Duration(seconds: 3),
        ),
      );
  }

  Future<void> _createPlan(BuildContext context, WidgetRef ref) async {
    String name = '';
    String objective = '';
    final weekdays = <int>{};

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova ficha de treino'),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      autofocus: false,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nome da ficha',
                      ),
                      onChanged: (value) {
                        name = value;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Objetivo'),
                      onChanged: (value) {
                        objective = value;
                      },
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Dias da semana',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(7, (day) {
                        return FilterChip(
                          label: Text(_weekdayLabel(day)),
                          selected: weekdays.contains(day),
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                weekdays.add(day);
                              } else {
                                weekdays.remove(day);
                              }
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancelar'),
                ),

                FilledButton(
                  onPressed: () {
                    if (name.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Informe o nome da ficha.'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Criar ficha'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || !context.mounted) {
      return;
    }

    ref
        .read(plansProvider.notifier)
        .create(
          name: name.trim(),
          objective: objective.trim().isEmpty
              ? 'Objetivo a definir'
              : objective.trim(),
          weekdays: weekdays.toList()..sort(),
        );
  }

  static String _weekdayLabel(int day) =>
      const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][day];
}

class TrainingPlanPage extends ConsumerWidget {
  const TrainingPlanPage({super.key, required this.planId});
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchingPlans = ref
        .watch(plansProvider)
        .where((item) => item.id == planId)
        .toList(growable: false);
    if (matchingPlans.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Esta ficha não está disponível.')),
      );
    }
    final plan = matchingPlans.first;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar para fichas',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/training'),
        ),
        title: Text(plan.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/training/$planId/exercises'),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar exercício'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VeroColors.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.track_changes_outlined,
                  color: VeroColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Objetivo da ficha',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        plan.objective,
                        style: const TextStyle(color: VeroColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (plan.exercises.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 36),
              child: Center(
                child: Text('Adicione exercícios para começar esta ficha.'),
              ),
            ),
          for (final plannedExercise in plan.exercises)
            _PlanExerciseTile(planId: planId, plannedExercise: plannedExercise),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

class _PlanExerciseTile extends ConsumerWidget {
  const _PlanExerciseTile({
    required this.planId,
    required this.plannedExercise,
  });
  final String planId;
  final PlannedExercise plannedExercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = ref
        .read(trainingRepositoryProvider)
        .exerciseById(plannedExercise.exerciseId);
    if (exercise == null) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xffE8F8F0),
          child: Icon(Icons.fitness_center, color: VeroColors.primary),
        ),
        title: Text(exercise.name),
        subtitle: Text(
          '${exercise.primaryMuscle} · ${plannedExercise.sets} séries × ${plannedExercise.repetitions} · descanso ${plannedExercise.restSeconds}s${plannedExercise.targetLoadKg == null ? '' : ' · ${plannedExercise.targetLoadKg!.toStringAsFixed(1)} kg'}',
        ),
        onTap: () => context.go(
          '/training/$planId/exercise/${plannedExercise.exerciseId}',
        ),
        trailing: IconButton(
          tooltip: 'Remover da ficha',
          onPressed: () => ref
              .read(plansProvider.notifier)
              .removeExercise(planId, plannedExercise.exerciseId),
          icon: const Icon(Icons.remove_circle_outline),
        ),
      ),
    );
  }
}

/// A dedicated route avoids stacking a dialog over a closing bottom sheet.
/// That sequence was responsible for the framework dependency assertion seen
/// while configuring an exercise on Android.
class TrainingExerciseConfigPage extends ConsumerStatefulWidget {
  const TrainingExerciseConfigPage({
    super.key,
    required this.planId,
    required this.exerciseId,
  });

  final String planId;
  final String exerciseId;

  @override
  ConsumerState<TrainingExerciseConfigPage> createState() =>
      _TrainingExerciseConfigPageState();
}

class _TrainingExerciseConfigPageState
    extends ConsumerState<TrainingExerciseConfigPage> {
  late final TextEditingController _sets;
  late final TextEditingController _repetitions;
  late final TextEditingController _load;
  late final TextEditingController _rest;
  late final TextEditingController _notes;
  PlannedExercise? _exercise;

  @override
  void initState() {
    super.initState();
    final plans = ref.read(plansProvider);
    final plan = plans.where((item) => item.id == widget.planId).firstOrNull;
    _exercise = plan?.exercises
        .where((item) => item.exerciseId == widget.exerciseId)
        .firstOrNull;
    final exercise = _exercise;
    _sets = TextEditingController(text: exercise?.sets.toString() ?? '3');
    _repetitions = TextEditingController(text: exercise?.repetitions ?? '10');
    _load = TextEditingController(
      text: exercise?.targetLoadKg?.toString() ?? '',
    );
    _rest = TextEditingController(
      text: exercise?.restSeconds.toString() ?? '60',
    );
    _notes = TextEditingController(text: exercise?.notes ?? '');
  }

  @override
  void dispose() {
    for (final controller in [_sets, _repetitions, _load, _rest, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _exercise;
    if (exercise == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configurar exercício')),
        body: const Center(
          child: Text('Exercício não encontrado nesta ficha.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/training/${widget.planId}'),
        ),
        title: const Text('Configurar exercício'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const Text(
            'Ajuste séries, repetições, carga e descanso.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'As alterações são aplicadas apenas após salvar.',
            style: TextStyle(color: VeroColors.muted),
          ),
          const SizedBox(height: 12),
          _field(_sets, 'Séries', number: true),
          _field(_repetitions, 'Repetições'),
          _field(_load, 'Carga alvo em kg (opcional)', number: true),
          _field(_rest, 'Descanso em segundos', number: true),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observações (opcional)',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar configurações'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      decoration: InputDecoration(labelText: label),
    ),
  );

  void _save() {
    final exercise = _exercise;
    final sets = int.tryParse(_sets.text);
    final rest = int.tryParse(_rest.text);
    if (exercise == null ||
        sets == null ||
        sets < 1 ||
        sets > 100 ||
        rest == null ||
        rest < 0 ||
        rest > 3600 ||
        _repetitions.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revise séries, repetições e descanso.')),
      );
      return;
    }
    ref
        .read(plansProvider.notifier)
        .updateExercise(
          widget.planId,
          exercise.copyWith(
            sets: sets,
            repetitions: _repetitions.text.trim(),
            targetLoadKg: double.tryParse(_load.text.replaceAll(',', '.')),
            restSeconds: rest,
            notes: _notes.text.trim(),
          ),
        );
    context.go('/training/${widget.planId}');
  }
}

class ExerciseLibraryPage extends ConsumerWidget {
  const ExerciseLibraryPage({super.key, this.planId});
  final String? planId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exercisesProvider);
    final catalog = ref.watch(catalogExercisesProvider);
    final muscle = ref.watch(exerciseMuscleFilterProvider);
    final equipment = ref.watch(exerciseEquipmentFilterProvider);
    final origin = ref.watch(exerciseOriginFilterProvider);
    final muscles = catalog.map((e) => e.primaryMuscle).toSet().toList()
      ..sort();
    final equipments = catalog.map((e) => e.equipment).toSet().toList()..sort();
    void clearFilters() {
      ref.read(exerciseSearchProvider.notifier).state = '';
      ref.read(exerciseMuscleFilterProvider.notifier).state = '';
      ref.read(exerciseEquipmentFilterProvider.notifier).state = '';
      ref.read(exerciseOriginFilterProvider.notifier).state = '';
      ref.read(exerciseSearchResetProvider.notifier).state++;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.go(planId == null ? '/training' : '/training/$planId'),
        ),
        title: Text(
          planId == null ? 'Biblioteca de exercícios' : 'Adicionar exercício',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createCustomExercise(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Criar exercício'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: TextField(
              key: ValueKey(ref.watch(exerciseSearchResetProvider)),
              onChanged: (value) =>
                  ref.read(exerciseSearchProvider.notifier).state = value,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar no catálogo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<String>(
                  value: muscle,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Todos os músculos'),
                    ),
                    for (final value in muscles)
                      DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (value) =>
                      ref.read(exerciseMuscleFilterProvider.notifier).state =
                          value ?? '',
                ),
                DropdownButton<String>(
                  value: equipment,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Todos os equipamentos'),
                    ),
                    for (final value in equipments)
                      DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (value) =>
                      ref.read(exerciseEquipmentFilterProvider.notifier).state =
                          value ?? '',
                ),
                DropdownButton<String>(
                  value: origin,
                  items: const [
                    DropdownMenuItem(
                      value: '',
                      child: Text('Todas as origens'),
                    ),
                    DropdownMenuItem(value: 'catalog', child: Text('Catálogo')),
                    DropdownMenuItem(
                      value: 'custom',
                      child: Text('Personalizados'),
                    ),
                  ],
                  onChanged: (value) =>
                      ref.read(exerciseOriginFilterProvider.notifier).state =
                          value ?? '',
                ),
                TextButton.icon(
                  onPressed: clearFilters,
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Limpar filtros'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Text('${exercises.length} exercícios encontrados'),
          ),
          if (exercises.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off, size: 42),
                    const SizedBox(height: 10),
                    const Text('Nenhum exercício encontrado.'),
                    OutlinedButton(
                      onPressed: clearFilters,
                      child: const Text('Limpar filtros'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (_, index) {
                  final exercise = exercises[index];
                  return Card(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: VeroColors.primary.withValues(alpha: .11),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.fitness_center_rounded,
                          color: VeroColors.primary,
                        ),
                      ),
                      title: Text(
                        exercise.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${exercise.primaryMuscle} · ${exercise.equipment}${exercise.isCustom ? ' · Personalizado' : ''}',
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (exercise.demoVideoAsset != null)
                            IconButton(
                              tooltip: 'Ver demonstração',
                              icon: const Icon(Icons.play_circle_outline),
                              onPressed: () =>
                                  _showExerciseDetails(context, exercise),
                            ),
                          if (exercise.isCustom && planId == null)
                            IconButton(
                              tooltip: 'Excluir exercício personalizado',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                ref
                                    .read(trainingRepositoryProvider)
                                    .deleteCustom(exercise.id);
                                ref
                                    .read(catalogRevisionProvider.notifier)
                                    .state++;
                              },
                            ),
                          Icon(
                            planId == null
                                ? Icons.arrow_forward_ios_rounded
                                : Icons.add_circle_outline,
                            size: planId == null ? 18 : 24,
                          ),
                        ],
                      ),
                      onTap: planId == null
                          ? () => _showExerciseDetails(context, exercise)
                          : () async {
                              ref
                                  .read(plansProvider.notifier)
                                  .addExercise(planId!, exercise.id);
                              await Future<void>.delayed(Duration.zero);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${exercise.name} adicionado à ficha.',
                                  ),
                                ),
                              );
                              context.go('/training/$planId');
                            },
                      onLongPress: exercise.isCustom && planId == null
                          ? () => _editCustomExercise(context, ref, exercise)
                          : null,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showExerciseDetails(
    BuildContext context,
    Exercise exercise,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('${exercise.primaryMuscle} · ${exercise.equipment}'),
                const SizedBox(height: 16),
                if (exercise.demoVideoAsset != null)
                  ExerciseDemoPlayer(assetPath: exercise.demoVideoAsset!)
                else
                  const Text(
                    'Ainda não há uma demonstração autorizada associada a este exercício.',
                  ),
                if (exercise.instructions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Como executar',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  for (final instruction in exercise.instructions)
                    Text('• $instruction'),
                ],
                if (exercise.safetyTips.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Cuidados',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  for (final tip in exercise.safetyTips) Text('• $tip'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createCustomExercise(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final name = TextEditingController();
    final muscle = TextEditingController();
    final equipment = TextEditingController();
    final create = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exercício personalizado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: muscle,
                decoration: const InputDecoration(labelText: 'Grupo muscular'),
              ),
              TextField(
                controller: equipment,
                decoration: const InputDecoration(labelText: 'Equipamento'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (create == true && name.text.trim().isNotEmpty && context.mounted) {
      ref
          .read(trainingRepositoryProvider)
          .createCustom(
            name: name.text,
            primaryMuscle: muscle.text.trim().isEmpty
                ? 'Não informado'
                : muscle.text,
            equipment: equipment.text.trim().isEmpty
                ? 'Não informado'
                : equipment.text,
          );
      final revision = ref.read(catalogRevisionProvider.notifier);
      revision.state = revision.state + 1;
    }
    name.dispose();
    muscle.dispose();
    equipment.dispose();
  }

  Future<void> _editCustomExercise(
    BuildContext context,
    WidgetRef ref,
    Exercise exercise,
  ) async {
    final name = TextEditingController(text: exercise.name);
    final muscle = TextEditingController(text: exercise.primaryMuscle);
    final equipment = TextEditingController(text: exercise.equipment);
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar exercício personalizado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: muscle,
              decoration: const InputDecoration(labelText: 'Grupo muscular'),
            ),
            TextField(
              controller: equipment,
              decoration: const InputDecoration(labelText: 'Equipamento'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (save == true && name.text.trim().isNotEmpty) {
      ref
          .read(trainingRepositoryProvider)
          .updateCustom(
            id: exercise.id,
            name: name.text,
            primaryMuscle: muscle.text.isEmpty ? 'Não informado' : muscle.text,
            equipment: equipment.text.isEmpty
                ? 'Não informado'
                : equipment.text,
          );
      ref.read(catalogRevisionProvider.notifier).state++;
    }
    name.dispose();
    muscle.dispose();
    equipment.dispose();
  }
}
