from pathlib import Path
import hashlib, re, csv
root=Path.cwd()
video=root/'assets/videos'
if not video.is_dir(): raise SystemExit('Execute na raiz Flutter.')
files=sorted(video.glob('*.mp4'))
groups={}
for f in files:
    base=re.sub(r' \(\d+\)$','',f.stem)
    groups.setdefault(base,[]).append(f)
print('Arquivos:',len(files),' | Exercicios-base:',len(groups))
for base,angles in sorted(groups.items()):
    if len(angles)>1: print('MULTIPLOS ANGULOS:',base,' -> ',len(angles),'arquivos')
print('Arquivos mantidos; nenhum video foi excluido.')
repo=root.parents[1]
backups=repo/'backups'
if backups.is_dir():
    for p in sorted(backups.iterdir()):
        if p.is_dir(): print('BACKUP:',p.name)
print('Somente leitura, sem limpeza automatica.')
