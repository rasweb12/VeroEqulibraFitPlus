import 'exercise.dart';

List<Exercise> filterExerciseCatalog(
  List<Exercise> items, {
  String query = '',
  String muscle = '',
  String equipment = '',
  String origin = '',
  String objective = '',
  String video = '',
}) {
  final text = _normalize(query);
  return items
      .where(
        (e) =>
            (text.isEmpty ||
                _normalize(e.name).contains(text) ||
                e.aliases.any((a) => _normalize(a).contains(text))) &&
            (muscle.isEmpty || e.primaryMuscle == muscle) &&
            (equipment.isEmpty || e.equipment == equipment) &&
            (objective.isEmpty || e.objective == objective) &&
            (video.isEmpty ||
                (video == 'with-video' && e.demoVideoAsset != null) ||
                (video == 'without-video' && e.demoVideoAsset == null)) &&
            (origin.isEmpty ||
                (origin == 'custom' && e.isCustom) ||
                (origin == 'catalog' && !e.isCustom)),
      )
      .toList(growable: false);
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp('[áàâãä]'), 'a')
    .replaceAll(RegExp('[éêë]'), 'e')
    .replaceAll(RegExp('[íîï]'), 'i')
    .replaceAll(RegExp('[óôõö]'), 'o')
    .replaceAll(RegExp('[úûü]'), 'u')
    .replaceAll('ç', 'c')
    .trim();
