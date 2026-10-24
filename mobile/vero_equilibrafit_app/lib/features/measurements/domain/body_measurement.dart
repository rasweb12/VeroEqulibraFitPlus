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

  BodyMeasurement copyWith({
    DateTime? recordedAt,
    double? weightKg,
    double? waistCm,
    double? chestCm,
    double? hipCm,
    String? notes,
  }) {
    return BodyMeasurement(
      id: id,
      recordedAt: recordedAt ?? this.recordedAt,
      weightKg: weightKg,
      waistCm: waistCm,
      chestCm: chestCm,
      hipCm: hipCm,
      notes: notes ?? this.notes,
    );
  }
}
