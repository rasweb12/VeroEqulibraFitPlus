import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/preferences_provider.dart';
import '../data/measurements_repository.dart';
import '../domain/body_measurement.dart';

final measurementsRepositoryProvider = Provider<MeasurementsRepository>(
  (ref) => MeasurementsRepository(preferences: ref.read(sharedPreferencesProvider)),
);

final measurementsProvider = StateNotifierProvider<MeasurementsController, List<BodyMeasurement>>(
  (ref) => MeasurementsController(ref.read(measurementsRepositoryProvider)),
);

class MeasurementsController extends StateNotifier<List<BodyMeasurement>> {
  MeasurementsController(this._repository) : super(_repository.all());
  final MeasurementsRepository _repository;
  void add({double? weightKg, double? waistCm, double? chestCm, double? hipCm, required String notes}) {
    _repository.add(weightKg: weightKg, waistCm: waistCm, chestCm: chestCm, hipCm: hipCm, notes: notes);
    state = _repository.all();
  }
  void delete(String id) { _repository.delete(id); state = _repository.all(); }
}
