import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../nutrition/presentation/nutrition_providers.dart';
import 'habits_page.dart';

class MissionsPage extends ConsumerWidget {
  const MissionsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final meals = ref.watch(mealsProvider);
    final today = DateTime.now();
    final todayMeals = meals
        .where(
          (meal) =>
              meal.recordedAt.year == today.year &&
              meal.recordedAt.month == today.month &&
              meal.recordedAt.day == today.day,
        )
        .length;
    final missions = [
      ('Registrar uma refeição', todayMeals, 1, Icons.restaurant_outlined),
      (
        'Acompanhar hidratação',
        habits.waterMl,
        habits.waterGoalMl,
        Icons.water_drop_outlined,
      ),
      (
        'Concluir mobilidade',
        habits.mobilityDone ? 1 : 0,
        1,
        Icons.self_improvement_outlined,
      ),
    ];
    final completed = missions.where((item) => item.$2 >= item.$3).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Missões de hoje')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '$completed de ${missions.length} missões concluídas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'As missões são opcionais e baseadas somente nos seus registros. Ajuste sua rotina sem punições.',
          ),
          const SizedBox(height: 16),
          ...missions.map((mission) {
            final progress = mission.$3 == 0
                ? 0.0
                : (mission.$2 / mission.$3).clamp(0.0, 1.0).toDouble();
            final done = progress >= 1;
            return Card(
              child: ListTile(
                leading: Icon(mission.$4),
                title: Text(mission.$1),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${mission.$2} / ${mission.$3}${mission.$1 == 'Acompanhar hidratação' ? ' ml' : ''}',
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: progress),
                  ],
                ),
                trailing: Icon(
                  done ? Icons.check_circle : Icons.circle_outlined,
                  color: done ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
