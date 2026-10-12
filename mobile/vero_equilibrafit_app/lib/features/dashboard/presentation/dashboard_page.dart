import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/presentation/app_drawer.dart';
import '../../habits/presentation/habits_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
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
            'Ainda não há sessões concluídas.',
            '/training',
          ),
          _section(
            context,
            Icons.restaurant_outlined,
            'Alimentação',
            'Nenhuma refeição registrada.',
            '/nutrition',
          ),
          _section(
            context,
            Icons.monitor_weight_outlined,
            'Evolução corporal',
            'Sem medidas ou fotos registradas.',
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
