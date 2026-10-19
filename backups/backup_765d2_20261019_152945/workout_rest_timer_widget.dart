import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/workout_rest_timer.dart';
import 'workout_session_providers.dart';

class WorkoutRestTimer extends ConsumerStatefulWidget {
  const WorkoutRestTimer({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<WorkoutRestTimer> createState() => WorkoutRestTimerState();
}

class WorkoutRestTimerState extends ConsumerState<WorkoutRestTimer> {
  WorkoutRestStore? _store;
  WorkoutRestState? _rest;
  Timer? _ticker;
  bool _busy = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _rest == null) return;
      setState(() {});
    });
  }

  Future<void> _load() async {
    final repo = ref.read(workoutSessionRepositoryProvider);
    final store = WorkoutRestStore(ownerId: repo.ownerId, store: repo.store);
    try {
      final value = await store.read(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _store = store;
        _rest = value;
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _store = store;
        _loaded = true;
      });
      _message('Não foi possível recuperar o descanso: $error');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _apply(WorkoutRestState? next) async {
    final store = _store;
    if (store == null || !_loaded || _busy) return;
    setState(() => _busy = true);
    try {
      if (next == null) {
        await store.clear(widget.sessionId);
      } else {
        await store.write(next);
      }
      if (mounted) setState(() => _rest = next);
    } catch (error) {
      _message('Não foi possível salvar o descanso: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Called only after a series has been persisted successfully.
  Future<void> start({
    required String exerciseName,
    required int seconds,
  }) async {
    if (!_loaded || _store == null) return;
    if (seconds <= 0) {
      await _apply(null);
      return;
    }
    await _apply(
      WorkoutRestState(
        sessionId: widget.sessionId,
        exerciseName: exerciseName,
        durationSeconds: seconds,
        remainingSeconds: seconds,
        paused: false,
        deadline: DateTime.now().toUtc().add(Duration(seconds: seconds)),
      ),
    );
  }

  Future<void> clear() => _apply(null);

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rest = _rest;
    if (rest == null) return const SizedBox.shrink();
    final seconds = rest.remainingAt(DateTime.now().toUtc());
    final finished = seconds == 0;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    final progress = rest.durationSeconds <= 0
        ? 0.0
        : (seconds / rest.durationSeconds).clamp(0.0, 1.0);

    return Card(
      key: const ValueKey('workout-rest-timer'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descanso · ${rest.exerciseName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$minutes:$remainder',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              finished
                  ? 'Descanso concluído. Pronto para a próxima série.'
                  : rest.paused
                  ? 'Descanso pausado'
                  : 'Descansando...',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (!finished)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _apply(
                            rest.paused
                                ? rest.resume(DateTime.now().toUtc())
                                : rest.pause(DateTime.now().toUtc()),
                          ),
                    icon: Icon(rest.paused ? Icons.play_arrow : Icons.pause),
                    label: Text(rest.paused ? 'Retomar' : 'Pausar'),
                  ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => start(
                          exerciseName: rest.exerciseName,
                          seconds: rest.durationSeconds,
                        ),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reiniciar'),
                ),
                TextButton(
                  onPressed: _busy ? null : clear,
                  child: const Text('Encerrar descanso'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
