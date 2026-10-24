import 'package:flutter_test/flutter_test.dart';
import 'package:vero_equilibrafit_app/core/persistence/secure_owner_store.dart';
import 'package:vero_equilibrafit_app/features/measurements/data/measurements_repository.dart';
import 'package:vero_equilibrafit_app/features/measurements/domain/body_measurement.dart';
import 'package:vero_equilibrafit_app/features/measurements/domain/measurement_selectors.dart';
import 'package:vero_equilibrafit_app/features/measurements/presentation/measurements_providers.dart';

BodyMeasurement measurement(String id, DateTime date, {double? weight}) =>
    BodyMeasurement(id: id, recordedAt: date, weightKg: weight);

void main() {
  test(
    'sorts records by measurement date with a stable same-date tie-breaker',
    () async {
      final repository = MeasurementsRepository(
        ownerId: 'a',
        store: MemorySecureOwnerStore(),
      );
      await repository.add(
        measurement: measurement('b', DateTime(2026, 10, 2), weight: 72),
      );
      await repository.add(
        measurement: measurement('a', DateTime(2026, 10, 2), weight: 71),
      );
      await repository.add(
        measurement: measurement('old', DateTime(2026, 9, 30), weight: 73),
      );

      expect(repository.all().map((item) => item.id), ['b', 'a', 'old']);
      expect(
        chronologicalMeasurements(repository.all()).map((item) => item.id),
        ['old', 'a', 'b'],
      );
    },
  );

  test(
    'current weight and variation ignore records without a valid weight',
    () {
      final history = [
        measurement('first', DateTime(2026, 10, 1), weight: 80),
        measurement('measure-only', DateTime(2026, 10, 2)),
        measurement('latest', DateTime(2026, 10, 3), weight: 78.5),
      ];
      expect(latestWeightMeasurement(history)?.id, 'latest');
      expect(weightChangeAcrossHistory(history), -1.5);
    },
  );

  test(
    'updates preserve the id and selected measurement date after reload',
    () async {
      final store = MemorySecureOwnerStore();
      final repository = MeasurementsRepository(ownerId: 'a', store: store);
      final original = measurement(
        'stable-id',
        DateTime(2026, 10, 1),
        weight: 70,
      );
      await repository.add(measurement: original);
      await repository.update(
        original.copyWith(recordedAt: DateTime(2026, 9, 29), weightKg: 69.5),
      );

      final restored = MeasurementsRepository(ownerId: 'a', store: store);
      await restored.load();
      expect(restored.all().single.id, 'stable-id');
      expect(restored.all().single.recordedAt, DateTime(2026, 9, 29));
      expect(restored.all().single.weightKg, 69.5);
    },
  );

  test('storage failure leaves confirmed history unchanged', () async {
    final repository = MeasurementsRepository(
      ownerId: 'a',
      store: _FailingStore(),
    );
    await expectLater(
      repository.add(
        measurement: measurement('x', DateTime(2026, 10, 1), weight: 70),
      ),
      throwsA(isA<StateError>()),
    );
    expect(repository.all(), isEmpty);
  });

  test('serializes consecutive controller writes', () async {
    final controller = MeasurementsController(
      MeasurementsRepository(ownerId: 'a', store: MemorySecureOwnerStore()),
    );
    await Future.wait([
      controller.add(
        recordedAt: DateTime(2026, 10, 1),
        weightKg: 70,
        notes: '',
      ),
      controller.add(
        recordedAt: DateTime(2026, 10, 2),
        weightKg: 69.5,
        notes: '',
      ),
    ]);
    expect(controller.state, hasLength(2));
    expect(latestWeightMeasurement(controller.state)?.weightKg, 69.5);
    controller.dispose();
  });
}

class _FailingStore implements SecureOwnerStore {
  @override
  Future<void> delete(String key) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) =>
      Future<void>.error(StateError('storage unavailable'));
}
