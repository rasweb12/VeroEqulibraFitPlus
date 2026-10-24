import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/preferences_provider.dart';
import '../../auth/presentation/current_owner_provider.dart';
import '../data/measurements_repository.dart';
import '../domain/body_measurement.dart';

final measurementsRepositoryProvider = Provider<MeasurementsRepository>(
  (ref) => MeasurementsRepository(
    ownerId: ref.watch(currentOwnerIdProvider),
    store: ref.read(secureOwnerStoreProvider),
  ),
);

final measurementsProvider =
    StateNotifierProvider<MeasurementsController, List<BodyMeasurement>>(
      (ref) => MeasurementsController(ref.read(measurementsRepositoryProvider)),
    );

class MeasurementsController extends StateNotifier<List<BodyMeasurement>> {
  MeasurementsController(this._repository) : super(const []) {
    _restore();
  }
  final MeasurementsRepository _repository;
  Future<void> _restore() async {
    await _repository.load();
    if (mounted) state = _repository.all();
  }

  void add({
    double? weightKg,
    double? waistCm,
    double? chestCm,
    double? hipCm,
    required String notes,
  }) {
    _repository.add(
      weightKg: weightKg,
      waistCm: waistCm,
      chestCm: chestCm,
      hipCm: hipCm,
      notes: notes,
    );
    state = _repository.all();
  }

  void delete(String id) {
    _repository.delete(id);
    state = _repository.all();
  }

  void update(
    String id, {
    double? weightKg,
    double? waistCm,
    double? chestCm,
    double? hipCm,
    required String notes,
  }) {
    _repository.update(
      id,
      weightKg: weightKg,
      waistCm: waistCm,
      chestCm: chestCm,
      hipCm: hipCm,
      notes: notes,
    );
    state = _repository.all();
  }
}
