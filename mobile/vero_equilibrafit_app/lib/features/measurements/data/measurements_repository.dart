import 'dart:convert';

import '../../../core/persistence/owner_scope.dart';
import '../../../core/persistence/secure_owner_store.dart';
import '../domain/body_measurement.dart';

class MeasurementsRepository {
  MeasurementsRepository({required String ownerId, required this.store})
    : _storageKey = ownerScopedKey(ownerId, 'body_measurements_v2_secure');

  final SecureOwnerStore store;
  final String _storageKey;
  final List<BodyMeasurement> _items = [];

  List<BodyMeasurement> all() => List.unmodifiable(_sorted(_items));

  Future<void> add({required BodyMeasurement measurement}) async {
    await _persist([..._items, measurement]);
  }

  Future<void> update(BodyMeasurement measurement) async {
    final index = _items.indexWhere((item) => item.id == measurement.id);
    if (index < 0) throw StateError('Registro de medida não encontrado.');
    final next = List<BodyMeasurement>.of(_items)..[index] = measurement;
    await _persist(next);
  }

  Future<void> delete(String id) async {
    final next = _items.where((item) => item.id != id).toList();
    if (next.length == _items.length) {
      throw StateError('Registro de medida não encontrado.');
    }
    await _persist(next);
  }

  Future<void> load() async {
    final encoded = await store.read(_storageKey);
    if (encoded == null || encoded.isEmpty) return;
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      final restored = <BodyMeasurement>[];
      for (final raw in decoded) {
        if (raw is! Map<String, dynamic>) continue;
        final recordedAt = DateTime.tryParse(
          raw['recordedAt'] as String? ?? '',
        );
        final id = raw['id'] as String?;
        if (recordedAt == null || id == null || id.isEmpty) continue;
        restored.add(
          BodyMeasurement(
            id: id,
            recordedAt: recordedAt.toLocal(),
            weightKg: (raw['weightKg'] as num?)?.toDouble(),
            waistCm: (raw['waistCm'] as num?)?.toDouble(),
            chestCm: (raw['chestCm'] as num?)?.toDouble(),
            hipCm: (raw['hipCm'] as num?)?.toDouble(),
            notes: raw['notes'] as String? ?? '',
          ),
        );
      }
      _items
        ..clear()
        ..addAll(restored);
    } on FormatException {
      // Keep unreadable encrypted storage untouched; do not destroy history.
    }
  }

  Future<void> _persist(List<BodyMeasurement> next) async {
    final encoded = jsonEncode(next.map(_toJson).toList(growable: false));
    await store.write(_storageKey, encoded);
    _items
      ..clear()
      ..addAll(next);
  }

  Map<String, Object?> _toJson(BodyMeasurement item) => {
    'id': item.id,
    'recordedAt': item.recordedAt.toUtc().toIso8601String(),
    'weightKg': item.weightKg,
    'waistCm': item.waistCm,
    'chestCm': item.chestCm,
    'hipCm': item.hipCm,
    'notes': item.notes,
  };

  List<BodyMeasurement> _sorted(Iterable<BodyMeasurement> values) {
    final sorted = List<BodyMeasurement>.of(values);
    sorted.sort((a, b) {
      final date = b.recordedAt.compareTo(a.recordedAt);
      return date != 0 ? date : b.id.compareTo(a.id);
    });
    return sorted;
  }
}
