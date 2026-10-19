import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/workout_session.dart';
import '../domain/workout_exercise_result.dart';
import '../domain/workout_set_result.dart';
import 'training_providers.dart';
import 'workout_session_providers.dart';
import 'workout_rest_timer_widget.dart';

// Vero 7.6.5D.2 - acessibilidade
class WorkoutSessionPage extends ConsumerStatefulWidget {
  const WorkoutSessionPage({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends ConsumerState<WorkoutSessionPage> {
  WorkoutSession? _session;
  final _restTimerKey = GlobalKey<WorkoutRestTimerState>();
  bool _busy = false;
  String? _error;

  // Rascunhos mantidos no Estado, nunca em controllers descartados pelo dialog.
  final Map<String, String> _repsDraft = {};
  final Map<String, String> _loadDraft = {};
  final Map<int, String> _notesDraft = {};

  String _setKey(int exerciseIndex, int setIndex) => '$exerciseIndex:$setIndex';

  @override
  void initState() {
    super.initState();
    Future.microtask(_initialize);
  }

  Future<void> _initialize() async {
    try {
      final training = ref.read(trainingRepositoryProvider);
      await training.load();
      final plan = training.planById(widget.planId);
      if (plan == null || plan.isArchived || plan.isDeleted) {
        throw StateError('Ficha ativa não encontrada.');
      }
      if (plan.exercises.isEmpty) {
        throw StateError('Adicione exercícios à ficha antes de iniciar.');
      }
      final session = await ref
          .read(workoutSessionRepositoryProvider)
          .start(
            plan: plan,
            exerciseName: (id) => training.exerciseById(id)?.name ?? id,
          );
      if (!mounted) return;
      _initializeDrafts(session);
      setState(() => _session = session);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  void _initializeDrafts(WorkoutSession session) {
    _repsDraft.clear();
    _loadDraft.clear();
    _notesDraft.clear();
    for (var i = 0; i < session.exercises.length; i++) {
      final exercise = session.exercises[i];
      _notesDraft[i] = exercise.notes;
      for (var j = 0; j < exercise.sets.length; j++) {
        final set = exercise.sets[j];
        final key = _setKey(i, j);
        _repsDraft[key] = set.repetitions == 0 ? '' : '${set.repetitions}';
        _loadDraft[key] = set.loadKg?.toString() ?? '';
      }
    }
  }

  WorkoutSession _snapshot(
    WorkoutSession current, {
    int? toggleExercise,
    int? toggleSet,
    bool? completed,
  }) {
    final exercises = <WorkoutExerciseResult>[];
    for (var i = 0; i < current.exercises.length; i++) {
      final exercise = current.exercises[i];
      final sets = <WorkoutSetResult>[];
      for (var j = 0; j < exercise.sets.length; j++) {
        final set = exercise.sets[j];
        final key = _setKey(i, j);
        final repsText = (_repsDraft[key] ?? '').trim();
        final loadText = (_loadDraft[key] ?? '').trim();
        final marking = i == toggleExercise && j == toggleSet;
        final isCompleted = marking
            ? (completed ?? set.completed)
            : set.completed;

        final reps = repsText.isEmpty ? 0 : int.tryParse(repsText);
        if (reps == null || reps < 0 || (isCompleted && reps == 0)) {
          throw FormatException(
            'Informe repetições válidas (> 0 para séries concluídas) na série ${j + 1} de ${exercise.exerciseName}.',
          );
        }
        final load = loadText.isEmpty
            ? null
            : double.tryParse(loadText.replaceAll(',', '.'));
        if (loadText.isNotEmpty &&
            (load == null || !load.isFinite || load < 0)) {
          throw FormatException(
            'Carga inválida na série ${j + 1} de ${exercise.exerciseName}.',
          );
        }

        sets.add(
          set.copyWith(
            repetitions: reps,
            loadKg: load,
            completed: isCompleted,
            completedAt: marking
                ? (isCompleted ? DateTime.now().toUtc() : null)
                : set.completedAt,
          ),
        );
      }
      exercises.add(
        exercise.copyWith(sets: sets, notes: _notesDraft[i] ?? exercise.notes),
      );
    }
    return current.copyWith(exercises: exercises);
  }

  Future<bool> _saveDraft({
    int? exerciseIndex,
    int? setIndex,
    bool? completed,
    WorkoutSessionStatus? status,
  }) async {
    final current = _session;
    if (current == null || _busy || current.isFinished) return false;
    setState(() => _busy = true);
    try {
      final updated = _snapshot(
        current,
        toggleExercise: exerciseIndex,
        toggleSet: setIndex,
        completed: completed,
      ).copyWith(status: status);
      await ref.read(workoutSessionRepositoryProvider).update(updated);
      if (!mounted) return false;
      setState(() => _session = updated);
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar: $error')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _goBack() async {
    final current = _session;
    if (current != null && !current.isFinished) {
      if (!await _saveDraft()) return;
    }
    if (mounted) context.go('/training');
  }

  Future<void> _togglePause() async {
    final current = _session;
    if (current == null) return;
    await _saveDraft(
      status: current.status == WorkoutSessionStatus.paused
          ? WorkoutSessionStatus.inProgress
          : WorkoutSessionStatus.paused,
    );
  }

  Future<void> _finish() async {
    if (_session == null || _busy) return;
    // Antes da confirmação, salva também campos não submetidos via teclado.
    if (!await _saveDraft()) return;
    if (!mounted) return;
    final current = _session!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalizar treino?'),
        content: Text(
          '${current.completedSets} de ${current.totalSets} séries concluídas. '
          'O resultado será registrado no histórico local.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continuar treino'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(workoutSessionRepositoryProvider).finish(current.id);
      if (mounted) {
        await _restTimerKey.currentState?.clear();
        if (mounted) context.go('/training');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao finalizar: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          // Vero 7.6.5B - refinamento visual da execucao
          title: Text(session?.planName ?? 'Iniciar treino'),
          leading: IconButton(
            tooltip: 'Voltar aos treinos',
            icon: const Icon(Icons.arrow_back),
            onPressed: _busy ? null : _goBack,
          ),
        ),
        body: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              )
            : session == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                session.status == WorkoutSessionStatus.paused
                                    ? Icons.pause_circle_outline
                                    : Icons.directions_run_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  session.status == WorkoutSessionStatus.paused
                                      ? 'Treino pausado'
                                      : 'Treino em andamento',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                session.totalSets == 0
                                    ? '0%'
                                    : '${(100 * session.completedSets / session.totalSets).round()}%',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Iniciado às ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(session.startedAt.toLocal()))}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${session.completedSets} de ${session.totalSets} séries concluídas',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Semantics(
                            label: 'Progresso do treino',
                            value:
                                '${session.completedSets} de ${session.totalSets} séries concluídas',
                            child: LinearProgressIndicator(
                              value: session.totalSets == 0
                                  ? 0
                                  : session.completedSets / session.totalSets,
                              minHeight: 9,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  WorkoutRestTimer(key: _restTimerKey, sessionId: session.id),
                  if (session.status == WorkoutSessionStatus.paused)
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.pause_circle_outline),
                        title: Text('Treino pausado'),
                        subtitle: Text('Retome para registrar novas séries.'),
                      ),
                    ),
                  for (var i = 0; i < session.exercises.length; i++)
                    _exerciseCard(session, i),
                ],
              ),
        bottomNavigationBar: session == null || _error != null
            ? null
            : SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _togglePause,
                        icon: Icon(
                          session.status == WorkoutSessionStatus.paused
                              ? Icons.play_arrow
                              : Icons.pause,
                        ),
                        label: Text(
                          session.status == WorkoutSessionStatus.paused
                              ? 'Retomar'
                              : 'Pausar',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _finish,
                        icon: const Icon(Icons.check),
                        label: const Text('Finalizar'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _exerciseCard(WorkoutSession session, int exerciseIndex) {
    final exercise = session.exercises[exerciseIndex];
    final canEdit = !_busy && session.status == WorkoutSessionStatus.inProgress;
    return Card(
      margin: const EdgeInsets.only(top: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.fitness_center, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${exercise.sets.where((set) => set.completed).length}/${exercise.sets.length}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'SÉRIES  ·  REPETIÇÕES  ·  CARGA',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            for (var j = 0; j < exercise.sets.length; j++)
              _setRow(exerciseIndex, j, exercise.sets[j], canEdit),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('notes-${session.id}-${exercise.exerciseId}'),
              initialValue: _notesDraft[exerciseIndex] ?? exercise.notes,
              enabled: canEdit,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observações do exercício',
                helperText: 'Anote orientações ou dificuldades desta execução.',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _notesDraft[exerciseIndex] = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _setRow(
    int exerciseIndex,
    int setIndex,
    WorkoutSetResult result,
    bool canEdit,
  ) {
    final key = _setKey(exerciseIndex, setIndex);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 49,
            child: Text(
              'Série ${result.setNumber}',
              style: TextStyle(
                fontWeight: result.completed
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: result.completed
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: ValueKey('reps-$key'),
              initialValue: _repsDraft[key],
              enabled: canEdit && !result.completed,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Reps',
                helperText: 'Série ${result.setNumber}',
                hintText: '0',
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => _repsDraft[key] = value,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: ValueKey('load-$key'),
              initialValue: _loadDraft[key],
              enabled: canEdit && !result.completed,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Kg',
                helperText: 'Carga em quilogramas',
                hintText: '0,0',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _loadDraft[key] = value,
            ),
          ),
          Checkbox(
            semanticLabel:
                'Série ${result.setNumber}: ${result.completed ? 'concluída' : 'pendente'}. Alterar conclusão',
            value: result.completed,
            onChanged: canEdit
                ? (value) async {
                    final markingComplete = value == true;
                    final saved = await _saveDraft(
                      exerciseIndex: exerciseIndex,
                      setIndex: setIndex,
                      completed: markingComplete,
                    );
                    if (!saved || !markingComplete || !mounted) return;
                    final session = _session;
                    if (session == null) return;
                    final exercise = session.exercises[exerciseIndex];
                    final plan = ref
                        .read(trainingRepositoryProvider)
                        .planById(widget.planId);
                    if (plan == null) return;
                    final matching = plan.exercises.where(
                      (entry) => entry.exerciseId == exercise.exerciseId,
                    );
                    if (matching.isEmpty) return;
                    await _restTimerKey.currentState?.start(
                      exerciseName: exercise.exerciseName,
                      seconds: matching.first.restSeconds,
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
