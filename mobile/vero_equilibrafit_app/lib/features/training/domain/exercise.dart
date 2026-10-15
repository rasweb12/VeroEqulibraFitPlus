class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    required this.equipment,
    this.aliases = const [],
    this.isCustom = false,
    this.demoVideoAsset,
    this.instructions = const [],
    this.safetyTips = const [],
  });
  final String id;
  final String name;
  final String primaryMuscle;
  final String equipment;
  final List<String> aliases;
  final bool isCustom;

  /// Local media is shown only when its exercise mapping was manually verified.
  final String? demoVideoAsset;
  final List<String> instructions;
  final List<String> safetyTips;
}
