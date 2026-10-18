import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../measurements/presentation/measurements_providers.dart';
import '../../../shared/presentation/vero_design.dart';
import 'nutrition_providers.dart';

class NutritionReportsPage extends ConsumerStatefulWidget {
  const NutritionReportsPage({super.key});
  @override
  ConsumerState<NutritionReportsPage> createState() =>
      _NutritionReportsPageState();
}

class _NutritionReportsPageState extends ConsumerState<NutritionReportsPage> {
  int _period = 7;
  @override
  Widget build(BuildContext context) {
    final meals = ref.watch(mealsProvider);
    final measurements = ref.watch(measurementsProvider);
    final start = DateTime.now().subtract(Duration(days: _period - 1));
    final selected = meals
        .where(
          (meal) => meal.recordedAt.isAfter(
            DateTime(
              start.year,
              start.month,
              start.day,
            ).subtract(const Duration(microseconds: 1)),
          ),
        )
        .toList();
    final calories = selected.fold<double>(
      0,
      (sum, meal) => sum + (meal.estimatedCalories ?? 0),
    );
    final protein = selected.fold<double>(
      0,
      (sum, meal) => sum + (meal.proteinGrams ?? 0),
    );
    final carbs = selected.fold<double>(
      0,
      (sum, meal) => sum + (meal.carbohydrateGrams ?? 0),
    );
    final fat = selected.fold<double>(
      0,
      (sum, meal) => sum + (meal.fatGrams ?? 0),
    );
    final weights = measurements
        .where(
          (item) => item.recordedAt.isAfter(start) && item.weightKg != null,
        )
        .toList();
    final days = List.generate(
      _period,
      (i) => DateTime.now().subtract(Duration(days: _period - 1 - i)),
    );
    final totals = days
        .map(
          (day) => meals
              .where((meal) => _sameDay(meal.recordedAt, day))
              .fold<double>(
                0,
                (sum, meal) => sum + (meal.estimatedCalories ?? 0),
              ),
        )
        .toList();
    final max = totals.fold<double>(
      0,
      (current, value) => value > current ? value : current,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Relatório nutricional')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7 dias')),
              ButtonSegment(value: 30, label: Text('30 dias')),
              ButtonSegment(value: 90, label: Text('90 dias')),
            ],
            selected: {_period},
            onSelectionChanged: (value) =>
                setState(() => _period = value.first),
          ),
          const SizedBox(height: 16),
          Text(
            'Dados registrados nos últimos $_period dias',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Text(
            'Calorias e macronutrientes podem ser estimativas. Fibras só aparecem quando registradas por uma fonte nutricional.',
          ),
          const SizedBox(height: 16),
          _metric(
            'Energia',
            '${calories.round()} kcal',
            selected.isEmpty
                ? 'Sem refeições no período'
                : 'Média ${(calories / _period).round()} kcal/dia',
          ),
          _metric(
            'Proteínas',
            '${protein.round()} g',
            'Carboidratos ${carbs.round()} g · Gorduras ${fat.round()} g',
          ),
          _metric(
            'Peso',
            weights.isEmpty
                ? 'Sem registros'
                : '${weights.first.weightKg!.toStringAsFixed(1)} kg',
            weights.length > 1
                ? 'Variação ${(weights.first.weightKg! - weights.last.weightKg!).toStringAsFixed(1)} kg no período'
                : 'Registre mais medidas para visualizar tendência',
          ),
          const SizedBox(height: 12),
          if (selected.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text('Registre refeições para visualizar a evolução.'),
              ),
            )
          else ...[
            Text(
              'Energia por dia',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < days.length; i++)
              _DayBar(day: days[i], calories: totals[i], maximum: max),
          ],
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  Widget _metric(String label, String value, String detail) => Card(
    child: ListTile(
      title: Text(label),
      subtitle: Text(detail, style: const TextStyle(color: VeroColors.muted)),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
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
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')} · ${calories.round()} kcal',
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: maximum == 0 ? 0 : calories / maximum,
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    ),
  );
}
