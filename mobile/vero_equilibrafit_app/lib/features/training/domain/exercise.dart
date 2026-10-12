class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    required this.equipment,
    this.aliases = const [],
    this.isCustom = false,
  });
  final String id;
  final String name;
  final String primaryMuscle;
  final String equipment;
  final List<String> aliases;
  final bool isCustom;
}
