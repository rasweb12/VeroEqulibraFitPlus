from pathlib import Path
import re, shutil, subprocess
root=Path.cwd()
catalog=root/'lib/features/training/data/training_repository.dart'
if not catalog.is_file():
    raise SystemExit('Execute na raiz Flutter.')
text=catalog.read_text(encoding='utf-8')
paths=sorted(set(re.findall(r"assets/videos/[^'\"\n]+?\.mp4",text)))
print('Videos referenciados:',len(paths))
for path in paths:
    f=root/path
    if not f.is_file():
        print('AUSENTE:',path)
        continue
    print('PRESENTE:',path,'bytes=',f.stat().st_size)
    if shutil.which('ffprobe'):
        x=subprocess.run(['ffprobe','-v','error','-show_entries','stream=codec_name,codec_type','-of','default=noprint_wrappers=1',str(f)],capture_output=True,text=True)
        print('  codecs:', (x.stdout or x.stderr).strip()[:400])
print('Arquivos encontrados em assets/videos:')
folder=root/'assets/videos'
if folder.is_dir():
    for f in sorted(folder.iterdir()):
        if f.is_file(): print(' ',f.name, f.stat().st_size,'bytes')
else: print('  Pasta ausente')
print('Somente leitura, sem alteracoes.')
