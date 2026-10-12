import 'package:flutter/material.dart';
import '../../../shared/presentation/app_drawer.dart';

class NutritionPage extends StatelessWidget {
  const NutritionPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Alimentação')),
    drawer: const AppDrawer(),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              'Nenhuma refeição registrada',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'O registro alimentar e os planos aprovados pelo usuário serão sincronizados pela API. Não há dados de demonstração aqui.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
