import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Identifica os arquivos de ângulos sem alterar os caminhos dos assets.
List<String> findExerciseAngles(String assetPath, Iterable<String> assets) {
  final base = assetPath.replaceFirst(
    RegExp(r'\.mp4$', caseSensitive: false),
    '',
  );
  final alternate = RegExp(
    '^${RegExp.escape(base)}(?: \\([0-9]+\\)|[0-9]+)\\.mp4\$',
    caseSensitive: false,
  );
  final all = assets.toList();
  final matches =
      all
          .where((item) => item != assetPath && alternate.hasMatch(item))
          .toList()
        ..sort();
  return [if (all.contains(assetPath)) assetPath, ...matches];
}

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
      final ordered = findExerciseAngles(widget.assetPath, all);
      if (!mounted) return;
      setState(() => _angles = ordered);
      await _open(ordered.isEmpty ? widget.assetPath : ordered.first);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _open(String path) async {
    final generation = ++_generation;
    final previous = _controller;
    _controller = null;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _selected = path;
      });
    }
    if (previous != null) await previous.dispose();
    final next = VideoPlayerController.asset(Uri.encodeFull(path));
    try {
      await next.initialize();
      await next.setLooping(true);
      await next.setPlaybackSpeed(_speed);
      if (!mounted || generation != _generation) {
        await next.dispose();
        return;
      }
      _controller = next;
      setState(() => _loading = false);
    } catch (error) {
      await next.dispose();
      if (mounted && generation == _generation) {
        setState(() {
          _error = error;
          _loading = false;
        });
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
            decoration: const InputDecoration(
              labelText: 'Ângulo da demonstração',
            ),
            items: [
              for (var i = 0; i < _angles.length; i++)
                DropdownMenuItem(
                  value: _angles[i],
                  child: Text('Ângulo ${i + 1}'),
                ),
            ],
            onChanged: _loading
                ? null
                : (value) {
                    if (value != null && value != _selected) _open(value);
                  },
          ),
          const SizedBox(height: 12),
        ],
        if (_loading)
          const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Não foi possível reproduzir este ângulo.'),
              const SizedBox(height: 6),
              SelectableText(
                'Detalhe técnico: $_error',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _selected == null
                    ? _discoverAngles
                    : () => _open(_selected!),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          )
        else if (controller != null && controller.value.isInitialized) ...[
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: VideoPlayer(controller),
            ),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: controller.value.isPlaying ? 'Pausar' : 'Reproduzir',
                icon: Icon(
                  controller.value.isPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle,
                ),
                onPressed: () async {
                  if (controller.value.isPlaying) {
                    await controller.pause();
                  } else {
                    await controller.play();
                  }
                  if (mounted) setState(() {});
                },
              ),
              IconButton(
                tooltip: 'Reiniciar',
                icon: const Icon(Icons.replay),
                onPressed: () => controller.seekTo(Duration.zero),
              ),
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
