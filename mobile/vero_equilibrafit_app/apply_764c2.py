"""Run from Flutter project root. Updates workout_session_page.dart only."""
from pathlib import Path
import shutil
p = Path('lib/features/training/presentation/workout_session_page.dart')
s = p.read_text(encoding='utf-8')
if 'workout_rest_timer_widget.dart' in s:
    raise SystemExit('Already patched; no changes made.')

def one(before, after):
    global s
    n=s.count(before)
    if n != 1:
        raise SystemExit(f'Expected one matching section, found {n}: {before[:80]}')
    s=s.replace(before, after, 1)

one("import 'workout_session_providers.dart';", "import 'workout_session_providers.dart';\nimport 'workout_rest_timer_widget.dart';")
one('  WorkoutSession? _session;\n', '  WorkoutSession? _session;\n  final _restTimerKey = GlobalKey<WorkoutRestTimerState>();\n')
one('      if (mounted) context.go(\'/training\');', "      if (mounted) {\n        await _restTimerKey.currentState?.clear();\n        if (mounted) context.go('/training');\n      }")
one('                  const SizedBox(height: 12),\n                  if (session.status == WorkoutSessionStatus.paused)', "                  const SizedBox(height: 12),\n                  WorkoutRestTimer(key: _restTimerKey, sessionId: session.id),\n                  if (session.status == WorkoutSessionStatus.paused)")
old='''            onChanged: canEdit
                ? (value) => _saveDraft(
                    exerciseIndex: exerciseIndex,
                    setIndex: setIndex,
                    completed: value ?? false,
                  )
                : null,'''
new='''            onChanged: canEdit
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
                    final plan = ref.read(trainingRepositoryProvider)
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
                : null,'''
one(old,new)
backup=p.with_suffix('.dart.backup_764c2')
shutil.copyfile(p, backup)
p.write_text(s,encoding='utf-8')
print('Patched:', p, '\nBackup:', backup)
