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
          path: '/exercises',
          builder: (context, state) => const ExerciseLibraryPage(),
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
}

class ExerciseLibraryPage extends ConsumerWidget {
  const ExerciseLibraryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exercisesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar exercício')),
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
                  trailing: const Icon(Icons.add_circle_outline),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
