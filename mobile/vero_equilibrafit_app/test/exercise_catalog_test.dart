import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vero_equilibrafit_app/features/training/data/exercise_catalog.dart';
import 'package:vero_equilibrafit_app/features/training/domain/exercise_catalog_filter.dart';

void main() {
  late final catalog = ExerciseCatalog.parse(
    File('assets/catalog/exercises.v1.json').readAsStringSync(),
  );

  test('importa exatamente os 200 exercícios oficiais com IDs estáveis', () {
    expect(catalog, hasLength(200));
    expect(catalog.map((item) => item.id).toSet(), hasLength(200));
    expect(
      catalog.map((item) => item.legacyId).toSet(),
      equals(Set<int>.from(List<int>.generate(200, (index) => index + 1))),
    );
    expect(catalog.first.id, 'exercise-001');
    expect(catalog.last.id, 'exercise-200');
  });

  test('mantém o mapeamento legado aprovado e os vídeos validados', () {
    final incline = catalog.singleWhere((item) => item.id == 'exercise-086');
    expect(incline.aliases, contains('incline-dumbbell'));
    expect(
      incline.demoVideoAsset,
      'assets/videos/Supino Inclinado com Halteres.mp4',
    );
    expect(catalog.where((item) => item.demoVideoAsset != null), hasLength(5));
  });

  test('pesquisa ignora acentos e inclui nomes oficiais', () {
    expect(
      filterExerciseCatalog(catalog, query: 'supino inclinado'),
      isNotEmpty,
    );
    expect(filterExerciseCatalog(catalog, query: 'rosca martelo'), isNotEmpty);
    expect(filterExerciseCatalog(catalog, query: 'panturrilha'), isNotEmpty);
  });

  test('filtro diferencia exercícios com e sem vídeo validado', () {
    expect(filterExerciseCatalog(catalog, video: 'with-video'), hasLength(5));
    expect(
      filterExerciseCatalog(catalog, video: 'without-video'),
      hasLength(195),
    );
  });
}
