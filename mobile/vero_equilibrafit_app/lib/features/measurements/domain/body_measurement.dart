class BodyMeasurement {
  const BodyMeasurement({
    required this.id,
    required this.recordedAt,
    this.weightKg,
    this.waistCm,
    this.chestCm,
    this.hipCm,
    this.notes = '',
  });

  final String id;
  final DateTime recordedAt;
  final double? weightKg;
  final double? waistCm;
  final double? chestCm;
  final double? hipCm;
  final String notes;
}
