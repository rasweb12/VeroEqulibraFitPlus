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
import 'core/offline/sync_providers.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff185b49),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff67d7b0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
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

class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('VeroEqulibraFit+'),
        actions: [
          IconButton(
            tooltip: 'Conta',
            onPressed: () => context.go('/auth'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Dashboard',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.dashboard_outlined),
          ),
          IconButton(
            tooltip: 'Biblioteca de exercícios',
            onPressed: () => context.go('/exercises'),
            icon: const Icon(Icons.fitness_center),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createPlan(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nova ficha'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seu ritmo. Seus resultados.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (plans.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Nenhuma ficha ativa. Crie ou recupere uma ficha quando desejar.',
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return Card(
                      child: ListTile(
                        title: Text(plan.name),
                        subtitle: Text(
                          '${plan.objective} · ${plan.exercises.length} exercícios${plan.weekdays.isEmpty ? '' : ' · ${plan.weekdays.map(_weekdayLabel).join(', ')}'}',
                        ),
                        onTap: () => context.go('/training/${plan.id}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) =>
                              _action(context, ref, plan.id, action),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'duplicate',
                              child: Text('Duplicar plano'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Excluir plano'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _action(
    BuildContext context,
    WidgetRef ref,
    String id,
    String action,
  ) async {
    if (action == 'duplicate') {
      ref.read(plansProvider.notifier).duplicate(id);
      return;
    }
    final plan = ref.read(plansProvider).firstWhere((item) => item.id == id);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir plano?'),
        content: Text(
          '“${plan.name}” será removido da lista. Seu histórico de treinos será preservado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir plano'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      ref.read(plansProvider.notifier).delete(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Plano excluído. O histórico permanece.'),
          action: SnackBarAction(
            label: 'DESFAZER',
            onPressed: () => ref.read(plansProvider.notifier).restore(id),
          ),
        ),
      );
    }
  }

  Future<void> _createPlan(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final objective = TextEditingController();
    final weekdays = <int>{};
    final create = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nova ficha de treino'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: objective,
                decoration: const InputDecoration(labelText: 'Objetivo'),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Dias da semana (opcional)'),
              ),
              Wrap(
                spacing: 6,
                children: List.generate(
                  7,
                  (day) => FilterChip(
                    label: Text(_weekdayLabel(day)),
                    selected: weekdays.contains(day),
                    onSelected: (selected) => setState(
                      () => selected ? weekdays.add(day) : weekdays.remove(day),
                    ),
                  ),
                ),
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
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
    if (create == true && name.text.trim().isNotEmpty && context.mounted) {
      ref
          .read(plansProvider.notifier)
          .create(
            name: name.text,
            objective: objective.text.trim().isEmpty
                ? 'Objetivo a definir'
                : objective.text,
            weekdays: weekdays.toList()..sort(),
          );
    }
    name.dispose();
    objective.dispose();
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
        padding: const EdgeInsets.all(20),
        children: [
          Text(plan.objective, style: Theme.of(context).textTheme.titleMedium),
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
        leading: const CircleAvatar(child: Icon(Icons.fitness_center)),
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
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Ajuste séries, repetições, carga e descanso.',
            style: Theme.of(context).textTheme.titleMedium,
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
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) =>
                  ref.read(exerciseSearchProvider.notifier).state = value,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar no catálogo',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (_, index) {
                final exercise = exercises[index];
                return ListTile(
                  title: Text(exercise.name),
                  subtitle: Text(
                    '${exercise.primaryMuscle} · ${exercise.equipment}${exercise.isCustom ? ' · Personalizado' : ''}',
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
                            ref.read(catalogRevisionProvider.notifier).state++;
                          },
                        ),
                      Icon(
                        planId == null
                            ? Icons.info_outline
                            : Icons.add_circle_outline,
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
