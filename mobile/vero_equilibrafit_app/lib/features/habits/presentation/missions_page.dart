import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../nutrition/presentation/nutrition_providers.dart';
import '../../../shared/presentation/app_drawer.dart';
import '../../../shared/presentation/vero_design.dart';
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
      drawer: const AppDrawer(),
      bottomNavigationBar: const VeroBottomNavigation(location: '/missions'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Builder(
            builder: (context) => VeroTopBar(
              title: 'Missões',
              onMenu: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: VeroColors.gold.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  color: VeroColors.gold,
                  size: 34,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completed de ${missions.length} missões concluídas',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Metas opcionais, sem punições.',
                        style: TextStyle(color: VeroColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
                leading: Icon(
                  mission.$4,
                  color: done ? VeroColors.primary : VeroColors.muted,
                ),
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
                  color: done ? VeroColors.primary : VeroColors.muted,
                ),
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => context.go('/habits'),
            icon: const Icon(Icons.water_drop_outlined),
            label: const Text('Voltar para hábitos'),
          ),
        ],
      ),
    );
  }
}
