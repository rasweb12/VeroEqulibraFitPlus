import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/training_progress_metrics.dart';
import 'workout_session_providers.dart';

class TrainingProgressPage extends ConsumerStatefulWidget {
  const TrainingProgressPage({super.key});

  @override
  ConsumerState<TrainingProgressPage> createState() =>
      _TrainingProgressPageState();
}

class _TrainingProgressPageState extends ConsumerState<TrainingProgressPage> {
  Future<void>? _load;
  int _days = 30;
  String? _exerciseId;

  @override
  void initState() {
    super.initState();
    _load = ref.read(workoutSessionRepositoryProvider).load();
  }

  // VERO_765D3C_RECOVERY: tenta novamente, sem alterar sessoes existentes.
  void _retryLoad() {
    setState(() {
      _load = ref.read(workoutSessionRepositoryProvider).load();
    });
  }

  String _number(double value) => value
      .toStringAsFixed(value == value.roundToDouble() ? 0 : 1)
      .replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha evolução'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar aos treinos',
          onPressed: () => context.go('/training'),
        ),
      ),
      body: FutureBuilder<void>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 44),
                    const SizedBox(height: 12),
                    Text(
                      'Não foi possível carregar a evolução',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Os dados não foram apagados. Tente novamente para recuperar seus indicadores.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _retryLoad,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/training'),
                      child: const Text('Voltar aos treinos'),
                    ),
                  ],
                ),
              ),
            );
          }
          final sessions = ref.read(workoutSessionRepositoryProvider).history();
          final data = TrainingProgressMetrics.calculate(sessions, days: _days);
          final selected = data.exercises
              .where((e) => e.id == _exerciseId)
              .firstOrNull;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // VERO_765C_VISUAL — cabeçalho da evolução
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        size: 34,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seu desempenho',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Indicadores locais de séries concluídas.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  for (final period in [7, 30, 90, 0])
                    ChoiceChip(
                      label: Text(period == 0 ? 'Todos' : '$period dias'),
                      selected: _days == period,
                      onSelected: (_) => setState(() {
                        _days = period;
                        _exerciseId = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (data.sessions == 0)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.show_chart_outlined, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          sessions.isEmpty
                              ? 'Você ainda não concluiu nenhum treino. Finalize uma sessão para acompanhar sua evolução.'
                              : 'Não existem treinos concluídos no período selecionado.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        if (sessions.isEmpty)
                          FilledButton.icon(
                            onPressed: () => context.go('/training'),
                            icon: const Icon(Icons.fitness_center),
                            label: const Text('Ver meus treinos'),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _days = 0;
                              _exerciseId = null;
                            }),
                            icon: const Icon(Icons.filter_alt_off_outlined),
                            label: const Text('Ver todo o período'),
                          ),
                      ],
                    ),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        context,
                        'Treinos',
                        '${data.sessions}',
                        Icons.fitness_center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metric(
                        context,
                        'Volume',
                        '${_number(data.volumeKg)} kg',
                        Icons.monitor_weight_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        context,
                        'Séries',
                        '${data.completedSets}/${data.totalSets}',
                        Icons.checklist,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metric(
                        context,
                        'Conclusão',
                        '${(data.completionRate * 100).toStringAsFixed(0)}%',
                        Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Volume por dia',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Soma de carga × repetições das séries concluídas com carga registrada.',
                ),
                const SizedBox(height: 12),
                _bars(context, data.points),
                const SizedBox(height: 20),
                Text(
                  'Evolução por exercício',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey(_days),
                  initialValue: selected?.id,
                  decoration: const InputDecoration(
                    labelText: 'Selecione um exercício',
                    border: OutlineInputBorder(),
                  ),
                  items: data.exercises
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _exerciseId = value),
                ),
                if (selected != null)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text('Sessões com o exercício: ${selected.sessions}'),
                          Text(
                            'Maior carga registrada: ${selected.maxKg == null ? 'Não registrada' : '${_number(selected.maxKg!)} kg'}',
                          ),
                          Text(
                            'Maior número de repetições em uma série: ${selected.maxRepetitions}',
                          ),
                          Text(
                            'Volume acumulado: ${_number(selected.volumeKg)} kg',
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/training/history'),
                  icon: const Icon(Icons.history),
                  label: const Text('Consultar histórico'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) => Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: Theme.of(context).textTheme.titleLarge),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );

  Widget _bars(BuildContext context, List<ProgressPoint> points) {
    if (points.isEmpty) return const Text('Sem volume registrado.');
    final recent = points.length > 14
        ? points.sublist(points.length - 14)
        : points;
    final maxVolume = recent.fold<double>(
      0,
      (max, p) => p.volumeKg > max ? p.volumeKg : max,
    );
    return SizedBox(
      height: 210,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final p in recent)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                      message:
                          '${p.date.day}/${p.date.month}: ${_number(p.volumeKg)} kg',
                      child: Container(
                        height: maxVolume <= 0
                            ? 2
                            : 150 * p.volumeKg / maxVolume + 2,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${p.date.day}/${p.date.month}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
