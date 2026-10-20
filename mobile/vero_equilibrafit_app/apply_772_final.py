from pathlib import Path
from datetime import datetime
import sys,shutil
root=Path.cwd(); app=root/'lib/app.dart'; check='--check' in sys.argv
if not (root/'pubspec.yaml').exists() or not app.exists(): sys.exit('CHECK FALHOU: raiz Flutter incorreta')
s=app.read_text(encoding='utf8'); start=s.find('  Future<void> _createCustomExercise(');end=s.find('\n}',start)
if 'VERO_772_FORM_FINAL' in s: sys.exit('JA APLICADO: sem alteracoes')
if start<0 or end<0 or s.count('  Future<void> _createCustomExercise(')!=1 or 'Future<void> _editCustomExercise(' not in s[start:end]: sys.exit('CHECK FALHOU: codigo local divergente; nada alterado')
replacement='''  // VERO_772_FORM_FINAL: formulario sem controladores a descartar.
  Future<void> _createCustomExercise(BuildContext context, WidgetRef ref) async {
    final result = await _customExerciseDialog(context);
    if (result == null || !context.mounted) return;
    ref.read(trainingRepositoryProvider).createCustom(
      name: result.$1, primaryMuscle: result.$2, equipment: result.$3,
    );
    ref.read(catalogRevisionProvider.notifier).state++;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exercício criado.')),
    );
  }

  Future<void> _editCustomExercise(
    BuildContext context, WidgetRef ref, Exercise exercise,
  ) async {
    final result = await _customExerciseDialog(context, exercise: exercise);
    if (result == null || !context.mounted) return;
    ref.read(trainingRepositoryProvider).updateCustom(
      id: exercise.id, name: result.$1,
      primaryMuscle: result.$2, equipment: result.$3,
    );
    ref.read(catalogRevisionProvider.notifier).state++;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exercício atualizado.')),
    );
  }

  Future<(String, String, String)?> _customExerciseDialog(
    BuildContext context, {Exercise? exercise},
  ) {
    var name = exercise?.name ?? '';
    var muscle = exercise?.primaryMuscle ?? '';
    var equipment = exercise?.equipment ?? '';
    var attempted = false;
    return showDialog<(String, String, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(exercise == null
              ? 'Criar exercício personalizado'
              : 'Editar exercício personalizado'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  initialValue: name, maxLength: 100,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nome do exercício',
                    border: const OutlineInputBorder(),
                    errorText: attempted && name.trim().isEmpty
                        ? 'Informe o nome do exercício' : null,
                  ),
                  onChanged: (v) => update(() => name = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: muscle, maxLength: 60,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Grupo muscular', helperText: 'Opcional',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => muscle = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: equipment, maxLength: 60,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Equipamento', helperText: 'Opcional',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => equipment = v,
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                update(() => attempted = true);
                if (name.trim().isEmpty) return;
                Navigator.pop(dialogContext, (
                  name.trim(),
                  muscle.trim().isEmpty ? 'Não informado' : muscle.trim(),
                  equipment.trim().isEmpty ? 'Não informado' : equipment.trim(),
                ));
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
'''
new=s[:start]+replacement+s[end:]
if new.count('VERO_772_FORM_FINAL')!=1: sys.exit('CHECK FALHOU: validação interna')
print('CHECK OK: apenas formularios de exercicios personalizados; player intacto')
if check: sys.exit(0)
backup=root.parents[1]/'backups'/('vero_772_final_'+datetime.now().strftime('%Y%m%d_%H%M%S'))
backup.mkdir(parents=True,exist_ok=False);shutil.copy2(app,backup/'app.dart');app.write_text(new,encoding='utf8')
print('APLICADO. Backup externo:',backup)
