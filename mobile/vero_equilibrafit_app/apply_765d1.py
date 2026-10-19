from pathlib import Path
import argparse, shutil, datetime, sys

ROOT = Path(__file__).resolve().parent
# Executar a partir da raiz do Flutter, não da pasta onde o instalador foi extraído.
APP = Path.cwd()
PRESENTATION = APP / 'lib' / 'features' / 'training' / 'presentation'
FILES = ('workout_history_detail_page.dart','training_progress_page.dart')

# Mudanças localizadas e verificáveis. Não alteram cálculos, persistência ou navegação.
def patch_detail(s):
    old = """                                Expanded(child: Text('Série ${set.setNumber}')),
                                Text('${set.repetitions} reps'),
                                const SizedBox(width: 12),
                                Text(
                                  set.loadKg == null
                                      ? 'Sem carga'
                                      : '${set.loadKg} kg',
                                ),"""
    new = """                                Expanded(child: Text('Série ${set.setNumber}')),
                                Flexible(
                                  child: Text(
                                    '${set.repetitions} reps',
                                    textAlign: TextAlign.end,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    set.loadKg == null
                                        ? 'Sem carga'
                                        : '${set.loadKg} kg',
                                    textAlign: TextAlign.end,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),"""
    return old,new

def patch_progress(s):
    old = """      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final p in recent)"""
    new = """      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
          for (final p in recent)"""
    # This change would require matching closing brackets and constraints; instead avoid unsafe patch.
    # Controlled accessibility patch: extra tooltip on chart's container already exists; not necessary.
    return None,None

parser = argparse.ArgumentParser(description='7.6.5D.1: alteração responsiva conservadora')
parser.add_argument('--check', action='store_true', help='Somente verificar se a correção é aplicável')
a = parser.parse_args()
path=PRESENTATION/FILES[0]
if not path.exists():
    sys.exit('Arquivo não encontrado: '+str(path))
original=path.read_text(encoding='utf-8')
old,new=patch_detail(original)
if new in original:
    print('Correção já presente; nenhuma alteração feita.')
    sys.exit(0)
if original.count(old)!=1:
    sys.exit('Versão diferente da esperada: nenhuma alteração feita. Envie o trecho das linhas com set.repetitions.')
if a.check:
    print('OK: trecho de detalhe encontrado. Execução normal criará backup e aplicará a correção.')
    sys.exit(0)
backup_root=APP.parents[1] / 'backups' / '765d1' # root project VeroEqulibraFitPlus/backups (APP parents[1] = APP\mobile parent)
backup_root.mkdir(parents=True,exist_ok=True)
backup=backup_root/(path.name+'.'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S')+'.bak')
shutil.copy2(path,backup)
path.write_text(original.replace(old,new), encoding='utf-8')
print('Corrigido:',path)
print('Backup:',backup)
print('Próximo passo: dart format lib/features/training/presentation/workout_history_detail_page.dart; flutter analyze; flutter test')
