import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/app_drawer.dart';
import 'measurements_providers.dart';

class MeasurementsPage extends ConsumerWidget {
  const MeasurementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(measurementsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolução corporal'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar medida'),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Registre peso ou medidas quando fizer sentido para você.',
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final values = <String>[
                  if (entry.weightKg != null)
                    '${entry.weightKg!.toStringAsFixed(1)} kg',
                  if (entry.waistCm != null)
                    'Cintura ${entry.waistCm!.toStringAsFixed(1)} cm',
                  if (entry.chestCm != null)
                    'Peito ${entry.chestCm!.toStringAsFixed(1)} cm',
                  if (entry.hipCm != null)
                    'Quadril ${entry.hipCm!.toStringAsFixed(1)} cm',
                ];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.monitor_weight_outlined),
                    title: Text(
                      values.isEmpty
                          ? 'Registro de evolução'
                          : values.join(' · '),
                    ),
                    subtitle: Text(
                      '${MaterialLocalizations.of(context).formatShortDate(entry.recordedAt)}${entry.notes.isEmpty ? '' : '\n${entry.notes}'}',
                    ),
                    isThreeLine: entry.notes.isNotEmpty,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Excluir registro',
                      onPressed: () => ref
                          .read(measurementsProvider.notifier)
                          .delete(entry.id),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final weight = TextEditingController();
    final waist = TextEditingController();
    final chest = TextEditingController();
    final hip = TextEditingController();
    final notes = TextEditingController();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registrar evolução'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _numberField(weight, 'Peso (kg)'),
              _numberField(waist, 'Cintura (cm)'),
              _numberField(chest, 'Peito (cm)'),
              _numberField(hip, 'Quadril (cm)'),
              TextField(
                controller: notes,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (save == true && context.mounted) {
      final values = [weight.text, waist.text, chest.text, hip.text];
      if (values.any(
            (value) => double.tryParse(value.replaceAll(',', '.')) != null,
          ) ||
          notes.text.trim().isNotEmpty) {
        double? parse(TextEditingController controller) =>
            double.tryParse(controller.text.replaceAll(',', '.'));
        ref
            .read(measurementsProvider.notifier)
            .add(
              weightKg: parse(weight),
              waistCm: parse(waist),
              chestCm: parse(chest),
              hipCm: parse(hip),
              notes: notes.text,
            );
      }
    }
    for (final controller in [weight, waist, chest, hip, notes]) {
      controller.dispose();
    }
  }

  Widget _numberField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      );
}
