import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nutrition_providers.dart';

class NutritionReportsPage extends ConsumerWidget {
  const NutritionReportsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealsProvider);
    final now = DateTime.now();
    final days = List.generate(
      7,
      (index) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index)),
    );
    final totals = days
        .map(
          (day) => meals
              .where((meal) => _sameDay(meal.recordedAt, day))
              .fold<double>(
                0,
                (total, meal) => total + (meal.estimatedCalories ?? 0),
              ),
        )
        .toList(growable: false);
    final maximum = totals.fold<double>(
      0,
      (max, total) => total > max ? total : max,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Relatório nutricional')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Últimos 7 dias', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Valores exibem somente refeições registradas. Estimativas nutricionais não são medições clínicas.',
          ),
          const SizedBox(height: 20),
          if (meals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text('Registre refeições para visualizar sua evolução.'),
              ),
            )
          else
            for (var index = 0; index < days.length; index++)
              _DayBar(
                day: days[index],
                calories: totals[index],
                maximum: maximum,
              ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.day,
    required this.calories,
    required this.maximum,
  });
  final DateTime day;
  final double calories;
  final double maximum;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')} · ${calories.round()} kcal',
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: maximum == 0 ? 0 : calories / maximum,
          minHeight: 12,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    ),
  );
}
