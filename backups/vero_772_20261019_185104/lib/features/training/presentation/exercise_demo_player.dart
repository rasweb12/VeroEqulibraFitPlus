import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Playback of a locally bundled, manually authorized exercise demonstration.
class ExerciseDemoPlayer extends StatefulWidget {
  const ExerciseDemoPlayer({super.key, required this.assetPath});
  final String assetPath;

  @override
  State<ExerciseDemoPlayer> createState() => _ExerciseDemoPlayerState();
}

class _ExerciseDemoPlayerState extends State<ExerciseDemoPlayer> {
  late final VideoPlayerController _controller;
  Object? _error;
  double _speed = 1;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..setLooping(true)
      ..initialize()
          .then((_) {
            if (mounted) setState(() {});
          })
          .catchError((Object error) {
            if (mounted) setState(() => _error = error);
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return const Text('Não foi possível reproduzir esta demonstração.');
    }
    if (!_controller.value.isInitialized) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: VideoPlayer(_controller),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: _controller.value.isPlaying ? 'Pausar' : 'Reproduzir',
              icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,
              ),
              onPressed: () => setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              }),
            ),
            IconButton(
              tooltip: 'Reiniciar',
              icon: const Icon(Icons.replay),
              onPressed: () => _controller.seekTo(Duration.zero),
            ),
            DropdownButton<double>(
              value: _speed,
              items: const [
                DropdownMenuItem(value: .5, child: Text('0,5×')),
                DropdownMenuItem(value: 1, child: Text('1×')),
                DropdownMenuItem(value: 1.5, child: Text('1,5×')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _speed = value);
                  _controller.setPlaybackSpeed(value);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
