from pathlib import Path
import sys, shutil, datetime, re
root=Path.cwd()
app=root/'lib/app.dart'
player=root/'lib/features/training/presentation/exercise_demo_player.dart'
if not (root/'pubspec.yaml').is_file() or not app.is_file() or not player.is_file():
    sys.exit('ERRO: execute na raiz Flutter.')
a=app.read_text(encoding='utf8'); p=player.read_text(encoding='utf8')
if 'VERO_772_MULTIANGLE' in a or 'VERO_772_MULTIANGLE' in p:
    sys.exit('A etapa ja parece instalada. Nao reaplique.')
old='''                if (exercise.demoVideoAsset != null)
                  ExerciseDemoPlayer(assetPath: exercise.demoVideoAsset!)'''
new='''                if (exercise.demoVideoAsset != null)
                  ExerciseDemoPlayer(assetPath: exercise.demoVideoAsset!)'''
# A biblioteca permanece intacta; os angulos serao descobertos a partir do manifesto de assets.
if a.count(old)!=1:
    sys.exit('CHECK FALHOU: widget de demonstracao diverge da versao esperada. Nada alterado.')
if 'class ExerciseDemoPlayer extends StatefulWidget' not in p or 'VideoPlayerController.asset(widget.assetPath)' not in p:
    sys.exit('CHECK FALHOU: reprodutor diverge. Nada alterado.')
if '--check' in sys.argv:
    print('CHECK OK: reprodutor identificado. app.dart e dados nao serao alterados.')
    sys.exit(0)
backup=root.parents[1]/'backups'/('vero_772_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
backup.mkdir(parents=True,exist_ok=False)
dest=backup/player.relative_to(root);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(player,dest)
player.write_text('''import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// VERO_772_MULTIANGLE: videos (1), (2) sao outros angulos, nao duplicatas.
class ExerciseDemoPlayer extends StatefulWidget {
  const ExerciseDemoPlayer({super.key, required this.assetPath});
  final String assetPath;
  @override
  State<ExerciseDemoPlayer> createState() => _ExerciseDemoPlayerState();
}

class _ExerciseDemoPlayerState extends State<ExerciseDemoPlayer> {
  VideoPlayerController? _controller;
  List<String> _angles = [];
  String? _selected;
  Object? _error;
  bool _loading = true;
  double _speed = 1;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _discoverAngles();
  }

  Future<void> _discoverAngles() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final all = manifest.listAssets();
      final base = widget.assetPath.replaceFirst(RegExp(r'\\.mp4$', caseSensitive: false), '');
      final matches = all.where((item) {
        if (item == widget.assetPath) return true;
        if (!item.startsWith('$base (') || !item.endsWith(').mp4')) return false;
        final number = item.substring(base.length + 2, item.length - 5);
        return int.tryParse(number) != null;
      }).toList()..sort();
      final ordered = <String>[
        if (all.contains(widget.assetPath)) widget.assetPath,
        ...matches.where((item) => item != widget.assetPath),
      ];
      if (!mounted) return;
      setState(() => _angles = ordered);
      await _open(ordered.isEmpty ? widget.assetPath : ordered.first);
    } catch (error) {
      if (!mounted) return;
      setState(() { _loading = false; _error = error; });
    }
  }

  Future<void> _open(String path) async {
    final generation = ++_generation;
    final previous = _controller;
    _controller = null;
    if (mounted) setState(() { _loading = true; _error = null; _selected = path; });
    if (previous != null) await previous.dispose();
    final next = VideoPlayerController.asset(path);
    try {
      await next.initialize();
      await next.setLooping(true);
      if (!mounted || generation != _generation) {
        await next.dispose();
        return;
      }
      _controller = next;
      setState(() => _loading = false);
    } catch (error) {
      await next.dispose();
      if (mounted && generation == _generation) {
        setState(() { _error = error; _loading = false; });
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_angles.length > 1) ...[
          DropdownButtonFormField<String>(
            key: ValueKey(_selected),
            initialValue: _selected,
            decoration: const InputDecoration(labelText: 'Ângulo da demonstração'),
            items: [
              for (var i = 0; i < _angles.length; i++)
                DropdownMenuItem(value: _angles[i], child: Text('Ângulo ${i + 1}')),
            ],
            onChanged: _loading ? null : (value) {
              if (value != null && value != _selected) _open(value);
            },
          ),
          const SizedBox(height: 12),
        ],
        if (_loading)
          const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Não foi possível reproduzir este ângulo.'),
              const SizedBox(height: 6),
              SelectableText('Detalhe técnico: $_error', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _selected == null ? _discoverAngles : () => _open(_selected!),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          )
        else if (controller != null && controller.value.isInitialized) ...[
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: ClipRRect(borderRadius: BorderRadius.circular(12), child: VideoPlayer(controller)),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: controller.value.isPlaying ? 'Pausar' : 'Reproduzir',
                icon: Icon(controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
                onPressed: () async {
                  if (controller.value.isPlaying) { await controller.pause(); }
                  else { await controller.play(); }
                  if (mounted) setState(() {});
                },
              ),
              IconButton(tooltip: 'Reiniciar', icon: const Icon(Icons.replay), onPressed: () => controller.seekTo(Duration.zero)),
              DropdownButton<double>(
                value: _speed,
                items: const [
                  DropdownMenuItem(value: .5, child: Text('0,5×')),
                  DropdownMenuItem(value: 1, child: Text('1×')),
                  DropdownMenuItem(value: 1.5, child: Text('1,5×')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _speed = value);
                  controller.setPlaybackSpeed(value);
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}
''',encoding='utf8')
print('INSTALADO: reprodutor com angulos e retry. Backup:',backup)
print('Execute: dart format lib/features/training/presentation/exercise_demo_player.dart; flutter analyze; flutter test')
