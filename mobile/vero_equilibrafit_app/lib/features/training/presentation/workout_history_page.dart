import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/workout_session.dart';
import 'workout_session_providers.dart';

class WorkoutHistoryPage extends ConsumerStatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  ConsumerState<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends ConsumerState<WorkoutHistoryPage> {
  Future<void>? _load;
  int _periodDays = 0;

  @override
  void initState() {
    super.initState();
    _load = ref.read(workoutSessionRepositoryProvider).load();
  }

  String _date(BuildContext context, DateTime value) {
    final local = value.toLocal();
    return MaterialLocalizations.of(context).formatMediumDate(local);
  }

  String _duration(WorkoutSession session) {
    final end = session.finishedAt;
    if (end == null) return 'Não registrada';
    final minutes = end.difference(session.startedAt).inMinutes;
    if (minutes < 0) return 'Não registrada';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return hours == 0 ? '$mins min' : '${hours}h ${mins}min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de treinos'),
        leading: IconButton(
          tooltip: 'Voltar aos treinos',
          onPressed: () => context.go('/training'),
          icon: const Icon(Icons.arrow_back),
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar o histórico: ${snapshot.error}',
                ),
              ),
            );
          }
          final repository = ref.read(workoutSessionRepositoryProvider);
          final sessions = repository.history().toList()
            ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
          final now = DateTime.now();
          final filtered = sessions.where((session) {
            if (_periodDays == 0) return true;
            final age = now.difference(session.startedAt.toLocal());
            return !age.isNegative && age < Duration(days: _periodDays);
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // VERO_765C_VISUAL — cabeçalho do histórico
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 34,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seus resultados',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Sessões finalizadas e salvas neste dispositivo.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _periodDays == 0,
                    onSelected: (_) => setState(() => _periodDays = 0),
                  ),
                  ChoiceChip(
                    label: const Text('7 dias'),
                    selected: _periodDays == 7,
                    onSelected: (_) => setState(() => _periodDays = 7),
                  ),
                  ChoiceChip(
                    label: const Text('30 dias'),
                    selected: _periodDays == 30,
                    onSelected: (_) => setState(() => _periodDays = 30),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    child: Column(
                      children: [
                        Icon(Icons.event_note_outlined, size: 42),
                        SizedBox(height: 12),
                        Text(
                          'Nenhum treino finalizado neste período.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              for (final session in filtered)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.go(
                      '/training/history/${Uri.encodeComponent(session.id)}',
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  session.planName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(_date(context, session.startedAt)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 14,
                            runSpacing: 6,
                            children: [
                              _metric(Icons.timer_outlined, _duration(session)),
                              _metric(
                                Icons.fitness_center,
                                '${session.exercises.length} exercícios',
                              ),
                              _metric(
                                Icons.checklist,
                                '${session.completedSets}/${session.totalSets} séries',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _metric(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
  );
}
