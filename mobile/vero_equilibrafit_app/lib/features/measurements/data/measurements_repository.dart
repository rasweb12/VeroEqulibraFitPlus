import 'dart:async';
import 'dart:convert';

import '../../../core/persistence/owner_scope.dart';
import '../../../core/persistence/secure_owner_store.dart';

import '../domain/body_measurement.dart';

class MeasurementsRepository {
  MeasurementsRepository({
    required String ownerId,
    required SecureOwnerStore store,
  }) : _store = store,
       _storageKey = ownerScopedKey(ownerId, 'body_measurements_v2_secure');
  final String _storageKey;
  final SecureOwnerStore _store;
  final List<BodyMeasurement> _items = [];

  List<BodyMeasurement> all() => List.unmodifiable(_items.reversed);

  void add({
    double? weightKg,
    double? waistCm,
    double? chestCm,
    double? hipCm,
    required String notes,
  }) {
    _items.add(
      BodyMeasurement(
        id: 'measurement-${DateTime.now().microsecondsSinceEpoch}',
        recordedAt: DateTime.now(),
        weightKg: weightKg,
        waistCm: waistCm,
        chestCm: chestCm,
        hipCm: hipCm,
        notes: notes.trim(),
      ),
    );
    unawaited(_save());
  }

  void delete(String id) {
    _items.removeWhere((item) => item.id == id);
    unawaited(_save());
  }

  Future<void> load() async {
    final encoded = await _store.read(_storageKey);
    if (encoded == null || encoded.isEmpty) return;
    try {
      for (final raw in jsonDecode(encoded) as List<dynamic>) {
        final item = raw as Map<String, dynamic>;
        final recordedAt = DateTime.tryParse(item['recordedAt'] as String);
        if (recordedAt == null) continue;
        _items.add(
          BodyMeasurement(
            id: item['id'] as String,
            recordedAt: recordedAt,
            weightKg: (item['weightKg'] as num?)?.toDouble(),
            waistCm: (item['waistCm'] as num?)?.toDouble(),
            chestCm: (item['chestCm'] as num?)?.toDouble(),
            hipCm: (item['hipCm'] as num?)?.toDouble(),
            notes: item['notes'] as String? ?? '',
          ),
        );
      }
    } on FormatException {
      // Ignore only this corrupt local cache; remote data is never removed.
    }
  }

  Future<void> _save() => _store.write(
    _storageKey,
    jsonEncode(
      _items
          .map(
            (item) => {
              'id': item.id,
              'recordedAt': item.recordedAt.toIso8601String(),
              'weightKg': item.weightKg,
              'waistCm': item.waistCm,
              'chestCm': item.chestCm,
              'hipCm': item.hipCm,
              'notes': item.notes,
            },
          )
          .toList(growable: false),
    ),
  );
}
