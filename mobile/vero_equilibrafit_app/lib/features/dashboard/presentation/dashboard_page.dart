import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/app_drawer.dart';
import '../../../shared/presentation/vero_design.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../habits/presentation/habits_page.dart';
import '../../measurements/presentation/measurements_providers.dart';
import '../../nutrition/presentation/nutrition_goals_page.dart';
import '../../nutrition/presentation/nutrition_providers.dart';
import '../../training/presentation/training_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final plans = ref
        .watch(plansProvider)
        .where((plan) => !plan.isDeleted)
        .toList();
    final meals = ref.watch(mealsProvider);
    final measurements = ref.watch(measurementsProvider);
    final goals = ref.watch(nutritionGoalsProvider);
    final session = ref.watch(authSessionProvider).valueOrNull;
    final today = DateTime.now();
    final todayMeals = meals
        .where((meal) => _sameDay(meal.recordedAt, today))
        .toList();
    final calories = todayMeals.fold<double>(
      0,
      (sum, meal) => sum + (meal.estimatedCalories ?? 0),
    );
    final plannedToday = plans
        .where(
          (plan) =>
              plan.weekdays.isEmpty || plan.weekdays.contains(today.weekday),
        )
        .length;
    final configured = <double>[];
    if (goals.calories > 0) {
      configured.add((calories / goals.calories).clamp(0, 1));
    }
    if (habits.waterGoalMl > 0) {
      configured.add((habits.waterMl / habits.waterGoalMl).clamp(0, 1));
    }
    if (plannedToday > 0) {
      configured.add(0); // Completion data is not available; never infer it.
    }
    final progress = configured.isEmpty
        ? null
        : configured.reduce((a, b) => a + b) / configured.length;
    final weight = measurements.isEmpty ? null : measurements.first.weightKg;
    final name = session?.displayName?.trim().isNotEmpty == true
        ? session!.displayName!.trim()
        : session?.email.split('@').first ?? 'você';

    return Scaffold(
      drawer: const AppDrawer(),
      bottomNavigationBar: const VeroBottomNavigation(location: '/'),
      body: Builder(
        builder: (context) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              VeroTopBar(
                title: 'Início',
                onMenu: () => Scaffold.of(context).openDrawer(),
              ),
              const SizedBox(height: 20),
              _Greeting(name: name, date: today),
              const SizedBox(height: 20),
              _DailyGoal(
                progress: progress,
                calories: calories,
                calorieGoal: goals.calories,
                water: habits.waterMl,
                waterGoal: habits.waterGoalMl,
                plannedWorkouts: plannedToday,
              ),
              const SizedBox(height: 20),
              VeroActionCard(
                icon: Icons.fitness_center_rounded,
                title: 'Treinos da semana',
                subtitle: plans.isEmpty
                    ? 'Crie sua primeira ficha quando desejar.'
                    : '${plans.length} ficha${plans.length == 1 ? '' : 's'} ativa${plans.length == 1 ? '' : 's'}.',
                tint: VeroColors.primaryBright,
                onTap: () => context.go('/training'),
              ),
              const SizedBox(height: 12),
              VeroActionCard(
                icon: Icons.restaurant_rounded,
                title: 'Alimentação',
                subtitle: todayMeals.isEmpty
                    ? 'Nenhuma refeição registrada hoje.'
                    : '${todayMeals.length} refeição${todayMeals.length == 1 ? '' : 'ões'} hoje${calories == 0 ? '.' : ' · ≈ ${calories.round()} kcal.'}',
                tint: const Color(0xffEA580C),
                onTap: () => context.go('/nutrition'),
              ),
              const SizedBox(height: 12),
              VeroActionCard(
                icon: Icons.monitor_weight_outlined,
                title: 'Evolução corporal',
                subtitle: measurements.isEmpty
                    ? 'Sem medidas registradas.'
                    : '${measurements.length} registro${measurements.length == 1 ? '' : 's'} de evolução${weight == null ? '.' : ' · ${weight.toStringAsFixed(1)} kg.'}',
                tint: const Color(0xff0D9488),
                onTap: () => context.go('/measurements'),
              ),
              const SizedBox(height: 12),
              _HydrationCard(
                current: habits.waterMl,
                goal: habits.waterGoalMl,
                onTap: () => context.go('/habits'),
              ),
              const SizedBox(height: 12),
              VeroActionCard(
                icon: Icons.auto_awesome_rounded,
                title: 'Coach Gemini',
                subtitle: 'Orientação disponível pela sua sessão autenticada.',
                tint: VeroColors.gemini,
                onTap: () => context.go('/coach'),
              ),
              const SizedBox(height: 12),
              VeroActionCard(
                icon: Icons.emoji_events_outlined,
                title: 'Missões',
                subtitle: 'Acompanhe metas opcionais no seu ritmo.',
                tint: VeroColors.gold,
                onTap: () => context.go('/missions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.date});
  final String name;
  final DateTime date;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: VeroColors.primaryBright.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Hoje, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: VeroColors.primary,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Olá, $name.',
        style: const TextStyle(
          fontSize: 26,
          height: 1.12,
          letterSpacing: -.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      const Text(
        'Seu ritmo.',
        style: TextStyle(
          fontSize: 28,
          height: 1.12,
          letterSpacing: -.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      const Text(
        'Seus resultados.',
        style: TextStyle(
          fontSize: 28,
          height: 1.12,
          letterSpacing: -.5,
          fontWeight: FontWeight.w800,
          color: VeroColors.primaryBright,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Seu painel mostra somente registros reais.',
        style: TextStyle(fontSize: 12, color: VeroColors.muted),
      ),
    ],
  );
}

class _DailyGoal extends StatelessWidget {
  const _DailyGoal({
    required this.progress,
    required this.calories,
    required this.calorieGoal,
    required this.water,
    required this.waterGoal,
    required this.plannedWorkouts,
  });
  final double? progress;
  final double calories;
  final int calorieGoal;
  final int water;
  final int waterGoal;
  final int plannedWorkouts;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'META DIÁRIA GERAL',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w800,
                  color: VeroColors.muted,
                ),
              ),
              Text(
                progress == null
                    ? 'Configure suas metas'
                    : '${(progress! * 100).round()}% acompanhado',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: VeroColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: const Color(0xffE7EEF8),
            color: VeroColors.primaryBright,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _Metric(
                label: 'Treino',
                value: plannedWorkouts == 0
                    ? 'Sem plano hoje'
                    : '$plannedWorkouts planejado${plannedWorkouts == 1 ? '' : 's'}',
              ),
              _Metric(
                label: 'Calorias',
                value: calorieGoal == 0
                    ? '${calories.round()} kcal'
                    : '${calories.round()} / $calorieGoal kcal',
              ),
              _Metric(
                label: 'Hidratação',
                value: waterGoal == 0 ? '$water ml' : '$water / $waterGoal ml',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: VeroColors.muted),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class _HydrationCard extends StatelessWidget {
  const _HydrationCard({
    required this.current,
    required this.goal,
    required this.onTap,
  });
  final int current;
  final int goal;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (current / goal).clamp(0, 1).toDouble() : null;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: VeroColors.water.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.water_drop_outlined,
                      color: VeroColors.water,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hidratação',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          goal == 0
                              ? '$current ml registrados hoje'
                              : '$current de $goal ml hoje',
                          style: const TextStyle(color: VeroColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: VeroColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                color: VeroColors.water,
                backgroundColor: const Color(0xffE7EEF8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
