import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/app_drawer.dart';
import 'nutrition_providers.dart';

class NutritionPage extends ConsumerWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Alimentação')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMeal(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar refeição'),
      ),
      body: meals.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.restaurant_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text('Registre sua primeira refeição', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                      'Use um registro simples agora e complemente com análise pelo Coach quando o serviço estiver configurado.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: meals.length,
              itemBuilder: (context, index) {
                final meal = meals[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.restaurant_outlined),
                    title: Text(meal.name),
                    subtitle: Text('${meal.mealType} · ${TimeOfDay.fromDateTime(meal.recordedAt).format(context)}${meal.notes.isEmpty ? '' : '\n${meal.notes}'}'),
                    isThreeLine: meal.notes.isNotEmpty,
                    trailing: IconButton(
                      tooltip: 'Excluir registro',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref.read(mealsProvider.notifier).delete(meal.id),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _addMeal(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final notes = TextEditingController();
    var mealType = 'Refeição';
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Registrar refeição'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'O que você comeu?')),
                DropdownButtonFormField<String>(
                  value: mealType,
                  decoration: const InputDecoration(labelText: 'Momento'),
                  items: const ['Café da manhã', 'Almoço', 'Lanche', 'Jantar', 'Refeição'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(growable: false),
                  onChanged: (value) => setState(() => mealType = value!),
                ),
                TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Observações (opcional)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (save == true && name.text.trim().isNotEmpty && context.mounted) {
      ref.read(mealsProvider.notifier).add(name: name.text, mealType: mealType, notes: notes.text);
    }
    name.dispose();
    notes.dispose();
  }
}
