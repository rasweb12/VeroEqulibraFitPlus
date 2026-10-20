from pathlib import Path
from collections import defaultdict
import re
root=Path.cwd();folder=root/'assets/videos'
if not folder.is_dir():raise SystemExit('Execute na raiz Flutter')
groups=defaultdict(list)
for p in folder.glob('*.mp4'):
    groups[re.sub(r' \(\d+\)$','',p.stem)].append(p.name)
print('MP4:',sum(map(len,groups.values())),'Grupos:',len(groups))
for k,v in sorted(groups.items()):
    if len(v)>1:print('ANGULOS',k,':',', '.join(sorted(v)))
for p in folder.glob('*.mp4'):
    m=re.search(r'(\d+)$',p.stem)
    if m and (folder/(p.stem[:m.start()]+'.mp4')).exists():print('CANDIDATO NUMERICO',p.name)
backups=root.parents[1]/'backups'
if backups.exists():
    for d in sorted(backups.iterdir()):
        if d.is_dir():
            fs=[p for p in d.rglob('*') if p.is_file()]
            print('BACKUP',d.name,'arquivos',len(fs),'MB',round(sum(p.stat().st_size for p in fs)/1048576,2))
print('Somente leitura; nada excluido.')
