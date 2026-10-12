import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/training/presentation/training_providers.dart';
import 'features/dashboard/presentation/dashboard_page.dart';
import 'features/habits/presentation/habits_page.dart';
import 'features/nutrition/presentation/nutrition_page.dart';
import 'features/coach/presentation/coach_page.dart';

class VeroEqulibraFitApp extends ConsumerWidget {
  const VeroEqulibraFitApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
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
    routerConfig: GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const DashboardPage()),
        GoRoute(
          path: '/training',
          builder: (context, state) => const PlansPage(),
        ),
        GoRoute(
          path: '/training/:planId',
          builder: (context, state) => TrainingPlanPage(
            planId: state.pathParameters['planId']!,
          ),
        ),
        GoRoute(
          path: '/exercises',
          builder: (context, state) => const ExerciseLibraryPage(),
        ),
        GoRoute(
          path: '/training/:planId/exercises',
          builder: (context, state) => ExerciseLibraryPage(
            planId: state.pathParameters['planId'],
          ),
        ),
        GoRoute(
          path: '/habits',
          builder: (context, state) => const HabitsPage(),
        ),
        GoRoute(
          path: '/nutrition',
          builder: (context, state) => const NutritionPage(),
        ),
        GoRoute(path: '/coach', builder: (context, state) => const CoachPage()),
      ],
    ),
  );
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
                          '${plan.objective} · ${plan.exercises.length} exercícios',
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
    final create = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
    );
    if (create == true && name.text.trim().isNotEmpty && context.mounted) {
      ref
          .read(plansProvider.notifier)
          .create(
            name: name.text,
            objective: objective.text.trim().isEmpty
                ? 'Objetivo a definir'
                : objective.text,
          );
    }
    name.dispose();
    objective.dispose();
  }
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
      appBar: AppBar(title: Text(plan.name)),
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
          for (final exerciseId in plan.exercises)
            _PlanExerciseTile(planId: planId, exerciseId: exerciseId),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

class _PlanExerciseTile extends ConsumerWidget {
  const _PlanExerciseTile({required this.planId, required this.exerciseId});
  final String planId;
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = ref.read(trainingRepositoryProvider).exerciseById(exerciseId);
    if (exercise == null) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.fitness_center)),
        title: Text(exercise.name),
        subtitle: Text('${exercise.primaryMuscle} · ${exercise.equipment}'),
        trailing: IconButton(
          tooltip: 'Remover da ficha',
          onPressed: () => ref
              .read(plansProvider.notifier)
              .removeExercise(planId, exerciseId),
          icon: const Icon(Icons.remove_circle_outline),
        ),
      ),
    );
  }
}

class ExerciseLibraryPage extends ConsumerWidget {
  const ExerciseLibraryPage({super.key, this.planId});
  final String? planId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exercisesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar exercício')),
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
                  trailing: Icon(
                    planId == null ? Icons.info_outline : Icons.add_circle_outline,
                  ),
                  onTap: planId == null
                      ? null
                      : () {
                          ref
                              .read(plansProvider.notifier)
                              .addExercise(planId!, exercise.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${exercise.name} adicionado à ficha.')),
                          );
                          context.go('/training/$planId');
                        },
                );
              },
            ),
          ),
        ],
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
}
