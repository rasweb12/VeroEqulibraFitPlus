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
  Future<void> _operations = Future<void>.value();
  Future<void> _restore() => _enqueue(() async {
    await _repository.load();
    if (mounted) state = _repository.all();
  });

  Future<void> add({
    required DateTime recordedAt,
    double? weightKg,
    double? waistCm,
    double? chestCm,
    double? hipCm,
    required String notes,
  }) => _enqueue(() async {
    await _repository.add(
      measurement: BodyMeasurement(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        recordedAt: recordedAt,
        weightKg: weightKg,
        waistCm: waistCm,
        chestCm: chestCm,
        hipCm: hipCm,
        notes: notes,
      ),
    );
    if (mounted) state = _repository.all();
  });

  Future<void> delete(String id) => _enqueue(() async {
    await _repository.delete(id);
    if (mounted) state = _repository.all();
  });

  Future<void> update(
    BodyMeasurement previous, {
    required DateTime recordedAt,
    double? weightKg,
    double? waistCm,
    double? chestCm,
    double? hipCm,
    required String notes,
  }) => _enqueue(() async {
    await _repository.update(
      BodyMeasurement(
        id: previous.id,
        recordedAt: recordedAt,
        weightKg: weightKg,
        waistCm: waistCm,
        chestCm: chestCm,
        hipCm: hipCm,
        notes: notes,
      ),
    );
    if (mounted) state = _repository.all();
  });

  Future<void> _enqueue(Future<void> Function() operation) {
    final task = _operations.then((_) => operation());
    _operations = task.catchError((_) {});
    return task;
  }
}
