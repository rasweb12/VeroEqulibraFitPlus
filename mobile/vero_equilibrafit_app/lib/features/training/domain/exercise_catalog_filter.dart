import 'exercise.dart';

List<Exercise> filterExerciseCatalog(
  List<Exercise> items, {
  String query = '',
  String muscle = '',
  String equipment = '',
  String origin = '',
}) {
  final text = query.trim().toLowerCase();
  return items
      .where(
        (e) =>
            (text.isEmpty ||
                e.name.toLowerCase().contains(text) ||
                e.aliases.any((a) => a.toLowerCase().contains(text))) &&
            (muscle.isEmpty || e.primaryMuscle == muscle) &&
            (equipment.isEmpty || e.equipment == equipment) &&
            (origin.isEmpty ||
                (origin == 'custom' && e.isCustom) ||
                (origin == 'catalog' && !e.isCustom)),
      )
      .toList(growable: false);
}
