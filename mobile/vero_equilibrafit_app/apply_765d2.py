from pathlib import Path
from datetime import datetime
import shutil
import sys

root = Path.cwd()
if not (root / 'pubspec.yaml').exists():
    sys.exit('ERRO: execute na raiz Flutter, onde esta o pubspec.yaml.')
folder = root / 'lib/features/training/presentation'
session = folder / 'workout_session_page.dart'
timer = folder / 'workout_rest_timer_widget.dart'
files = [session,timer]
if not all(p.is_file() for p in files):
    sys.exit('ERRO: um dos arquivos Dart nao existe. Nenhuma alteracao aplicada.')

mark = '// Vero 7.6.5D.2 - acessibilidade\n'
a = session.read_text(encoding='utf-8')
b = timer.read_text(encoding='utf-8')
if mark.strip() in a and mark.strip() in b:
    print('Already patched; no changes made.')
    sys.exit(0)
if mark.strip() in a or mark.strip() in b:
    sys.exit('ERRO: instalacao parcial detectada. Nenhuma alteracao aplicada.')


def one(s, original, updated, file):
    n = s.count(original)
    if n != 1:
        raise ValueError(f'{file}: ancora nao encontrada ou duplicada ({n}): {original[:85]!r}')
    return s.replace(original, updated, 1)

try:
    a = one(a, 'class WorkoutSessionPage extends ConsumerStatefulWidget {', mark + 'class WorkoutSessionPage extends ConsumerStatefulWidget {','session')
    a = one(a, "labelText: 'Observações do exercício',", "labelText: 'Observações do exercício',\n                helperText: 'Anote orientações ou dificuldades desta execução.',",'session')
    a = one(a, "labelText: 'Reps',\n", "labelText: 'Reps',\n                helperText: 'Série ${result.setNumber}',\n",'session')
    a = one(a, "labelText: 'Kg',\n", "labelText: 'Kg',\n                helperText: 'Carga em quilogramas',\n",'session')
    a = one(a, '          Checkbox(\n            value: result.completed,', "          Checkbox(\n            semanticLabel: 'Série ${result.setNumber}: ${result.completed ? 'concluída' : 'pendente'}. Alterar conclusão',\n            value: result.completed,",'session')
    a = one(a, "                          LinearProgressIndicator(\n                            value: session.totalSets == 0", "                          Semantics(\n                            label: 'Progresso do treino',\n                            value: '${session.completedSets} de ${session.totalSets} séries concluídas',\n                            child: LinearProgressIndicator(\n                            value: session.totalSets == 0",'session')
    a = one(a, "                            borderRadius: BorderRadius.circular(8),\n                          ),\n                        ],", "                            borderRadius: BorderRadius.circular(8),\n                            ),\n                          ),\n                        ],",'session')
    b = one(b, 'class WorkoutRestTimer extends ConsumerStatefulWidget {', mark + 'class WorkoutRestTimer extends ConsumerStatefulWidget {','timer')
    b = one(b, "            Text(\n              '$minutes:$remainder',\n              style: Theme.of(context).textTheme.headlineMedium,\n            ),", "            Semantics(\n              label: 'Tempo restante do descanso',\n              value: '$minutes minutos e $remainder segundos',\n              child: ExcludeSemantics(\n                child: Text(\n                  '$minutes:$remainder',\n                  style: Theme.of(context).textTheme.headlineMedium,\n                ),\n              ),\n            ),",'timer')
    b = one(b, '            LinearProgressIndicator(value: progress),', "            Semantics(\n              label: 'Progresso do descanso',\n              value: '${(progress * 100).round()} por cento restante',\n              child: LinearProgressIndicator(value: progress),\n            ),",'timer')
    b = one(b, "                    label: Text(rest.paused ? 'Retomar' : 'Pausar'),", "                    label: Text(rest.paused ? 'Retomar descanso' : 'Pausar descanso'),",'timer')
    b = one(b, "                  label: const Text('Reiniciar'),", "                  label: const Text('Reiniciar descanso'),",'timer')
except ValueError as ex:
    sys.exit('ERRO: ' + str(ex) + '\nNenhuma alteracao aplicada.')

if '--check' in sys.argv:
    print('CHECK OK: as alteracoes podem ser aplicadas aos dois arquivos.')
    sys.exit(0)

# Repository root is .../VeroEqulibraFitPlus; keep backup outside Flutter root.
repo = root.parents[1] if root.parent.name == 'mobile' else root.parent
backup = repo / 'backups' / ('backup_765d2_' + datetime.now().strftime('%Y%m%d_%H%M%S'))
backup.mkdir(parents=True, exist_ok=False)
for p in files:
    shutil.copy2(p, backup / p.name)
try:
    session.write_text(a, encoding='utf-8')
    timer.write_text(b, encoding='utf-8')
except Exception:
    for p in files:
        shutil.copy2(backup / p.name, p)
    raise
print('OK: melhorias aplicadas em ambos os arquivos.')
print('Backup:', backup)
print('Execute: dart format lib/features/training/presentation/workout_session_page.dart lib/features/training/presentation/workout_rest_timer_widget.dart')
print('Execute: flutter analyze && flutter test')
