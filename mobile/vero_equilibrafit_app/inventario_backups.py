from pathlib import Path
root=Path.cwd()
repo=root.parent.parent
for base in (repo / 'backups',root):
    if base.exists():
        for folder in sorted(base.glob('backup*')):
            if folder.is_dir():
                files=[p for p in folder.rglob('*') if p.is_file()]
                size=sum(p.stat().st_size for p in files)
                print(f'{folder} | {len(files)} arquivos | {size/1048576:.2f} MB')
print('Somente inventario: nenhum arquivo foi apagado.')
