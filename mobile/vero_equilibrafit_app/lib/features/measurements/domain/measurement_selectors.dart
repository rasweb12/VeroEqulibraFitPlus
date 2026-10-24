import 'body_measurement.dart';

/// Orders a history by the date the measurement was taken, then its stable ID.
/// The second comparison keeps same-day records deterministic.
List<BodyMeasurement> chronologicalMeasurements(
  Iterable<BodyMeasurement> measurements,
) {
  final ordered = List<BodyMeasurement>.of(measurements);
  ordered.sort((a, b) {
    final byDate = a.recordedAt.compareTo(b.recordedAt);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  });
  return ordered;
}

List<BodyMeasurement> chronologicalWeightMeasurements(
  Iterable<BodyMeasurement> measurements,
) => chronologicalMeasurements(
  measurements.where((entry) => entry.weightKg != null && entry.weightKg! > 0),
);

BodyMeasurement? latestWeightMeasurement(
  Iterable<BodyMeasurement> measurements,
) {
  final weights = chronologicalWeightMeasurements(measurements);
  return weights.isEmpty ? null : weights.last;
}

double? weightChangeAcrossHistory(Iterable<BodyMeasurement> measurements) {
  final weights = chronologicalWeightMeasurements(measurements);
  if (weights.length < 2) return null;
  return weights.last.weightKg! - weights.first.weightKg!;
}
