import 'package:flutter_test/flutter_test.dart';
import 'package:vero_equilibrafit_app/features/training/presentation/exercise_demo_player.dart';

void main() {
  test('reconhece ângulos numerados sem associar outros exercícios', () {
    const base = 'assets/videos/Supino Inclinado com Halteres.mp4';
    expect(
      findExerciseAngles(base, [
        'assets/videos/Supino Inclinado com Halteres2.mp4',
        'assets/videos/Supino Inclinado com Halteres (1).mp4',
        'assets/videos/Supino Inclinado com Halteres extra.mp4',
        base,
      ]),
      [
        base,
        'assets/videos/Supino Inclinado com Halteres (1).mp4',
        'assets/videos/Supino Inclinado com Halteres2.mp4',
      ],
    );
  });
}
