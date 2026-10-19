import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/workout_session.dart';
import 'workout_session_providers.dart';

class WorkoutHistoryDetailPage extends ConsumerStatefulWidget {
  const WorkoutHistoryDetailPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<WorkoutHistoryDetailPage> createState() =>
      _WorkoutHistoryDetailPageState();
}

class _WorkoutHistoryDetailPageState
    extends ConsumerState<WorkoutHistoryDetailPage> {
  Future<void>? _load;

  @override
  void initState() {
    super.initState();
    _load = ref.read(workoutSessionRepositoryProvider).load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do treino'),
        leading: IconButton(
          tooltip: 'Voltar ao histórico',
          onPressed: () => context.go('/training/history'),
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
              child: Text('Erro ao carregar sessão: ${snapshot.error}'),
            );
          }
          final session = ref
              .read(workoutSessionRepositoryProvider)
              .byId(widget.sessionId);
          if (session == null ||
              session.status != WorkoutSessionStatus.completed) {
            return const Center(
              child: Text('Treino concluído não encontrado.'),
            );
          }
          final end = session.finishedAt;
          final duration = end?.difference(session.startedAt);
          final minutes = duration == null || duration.isNegative
              ? null
              : duration.inMinutes;
          final date = MaterialLocalizations.of(
            context,
          ).formatMediumDate(session.startedAt.toLocal());
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                session.planName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text('Concluído • $date'),
              const SizedBox(height: 6),
              Text(
                'Duração: ${minutes == null ? "Não registrada" : "$minutes min"}',
              ),
              Text(
                'Séries: ${session.completedSets}/${session.totalSets} concluídas',
              ),
              const SizedBox(height: 14),
              for (final exercise in session.exercises)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.exerciseName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final set in exercise.sets)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  set.completed
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: set.completed ? Colors.green : null,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Série ${set.setNumber}')),
                                Text('${set.repetitions} reps'),
                                const SizedBox(width: 12),
                                Text(
                                  set.loadKg == null
                                      ? 'Sem carga'
                                      : '${set.loadKg} kg',
                                ),
                              ],
                            ),
                          ),
                        if (exercise.notes.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Observações: ${exercise.notes}'),
                        ],
                      ],
                    ),
                  ),
                ),
              if (session.notes.trim().isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text('Observações da sessão: ${session.notes}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
