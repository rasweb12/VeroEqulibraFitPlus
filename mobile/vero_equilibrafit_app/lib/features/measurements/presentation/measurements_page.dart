import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/app_drawer.dart';
import '../../../shared/presentation/vero_design.dart';
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
      bottomNavigationBar: const VeroBottomNavigation(
        location: '/measurements',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar medida'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        itemCount: entries.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final current = entries.isEmpty ? null : entries.first.weightKg;
            final first = entries.isEmpty ? null : entries.last.weightKg;
            final change = current != null && first != null
                ? current - first
                : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xffF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ÚLTIMO REGISTRO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: VeroColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              current == null
                                  ? 'Sem peso'
                                  : '${current.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            change == null
                                ? 'Meta não configurada'
                                : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg desde o início',
                            style: const TextStyle(
                              fontSize: 12,
                              color: VeroColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        entries.isEmpty
                            ? 'Registre peso ou medidas quando fizer sentido para você.'
                            : '${entries.length} registro(s) no histórico.',
                        style: const TextStyle(color: VeroColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Histórico de medições',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 10),
                if (entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: Text('Ainda não há medições.')),
                  ),
              ],
            );
          }
          final entry = entries[index - 1];
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
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffF1F5F9)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: VeroColors.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.monitor_weight_outlined,
                  color: VeroColors.primary,
                ),
              ),
              title: Text(
                values.isEmpty ? 'Registro de evolução' : values.join(' · '),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${MaterialLocalizations.of(context).formatShortDate(entry.recordedAt)}${entry.notes.isEmpty ? '' : '\n${entry.notes}'}',
              ),
              isThreeLine: entry.notes.isNotEmpty,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Excluir registro',
                onPressed: () =>
                    ref.read(measurementsProvider.notifier).delete(entry.id),
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
    // A dialog route completes before all of its inherited dependencies have
    // been detached. Deferring the provider update by one frame prevents a
    // route disposal/provider rebuild race on Android while preserving the
    // modal flow.
    await _afterDialogFrame();
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

  Future<void> _afterDialogFrame() async {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
    await completer.future;
  }

  Widget _numberField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      );
}
