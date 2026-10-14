import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/presentation/app_drawer.dart';
import '../../habits/presentation/habits_page.dart';
import '../../nutrition/presentation/nutrition_providers.dart';
import '../../training/presentation/training_providers.dart';
import '../../measurements/presentation/measurements_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final plans = ref.watch(plansProvider);
    final meals = ref.watch(mealsProvider);
    final measurements = ref.watch(measurementsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('VeroEqulibraFit+')),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Seu ritmo. Seus resultados.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Seu painel mostra somente registros reais.'),
          const SizedBox(height: 20),
          _section(
            context,
            Icons.fitness_center,
            'Treinos da semana',
            plans.isEmpty
                ? 'Crie sua primeira ficha quando desejar.'
                : '${plans.length} ficha${plans.length == 1 ? '' : 's'} ativa${plans.length == 1 ? '' : 's'}.',
            '/training',
          ),
          _section(
            context,
            Icons.restaurant_outlined,
            'Alimentação',
            meals.isEmpty
                ? 'Nenhuma refeição registrada.'
                : meals.length == 1
                    ? '1 refeição registrada.'
                    : '${meals.length} refeições registradas.',
            '/nutrition',
          ),
          _section(
            context,
            Icons.monitor_weight_outlined,
            'Evolução corporal',
            measurements.isEmpty
                ? 'Sem medidas registradas.'
                : '${measurements.length} registro${measurements.length == 1 ? '' : 's'} de evolução.',
            '/measurements',
          ),
          _section(
            context,
            Icons.water_drop_outlined,
            'Hidratação',
            '${habits.waterMl} ml registrados hoje.',
            '/habits',
          ),
          _section(
            context,
            Icons.auto_awesome_outlined,
            'Coach Gemini',
            'Disponível após configurar a API segura.',
            '/coach',
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, [
    String? route,
  ]) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: route == null ? null : const Icon(Icons.chevron_right),
      onTap: route == null ? null : () => context.go(route),
    ),
  );
}
