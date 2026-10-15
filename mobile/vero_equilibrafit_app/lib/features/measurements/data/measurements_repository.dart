import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/persistence/owner_scope.dart';

import '../domain/body_measurement.dart';

class MeasurementsRepository {
  MeasurementsRepository({required String ownerId, SharedPreferences? preferences})
    : _preferences = preferences,
      _storageKey = ownerScopedKey(ownerId, 'body_measurements_v2') {
    _restore();
  }
  final String _storageKey;
  final SharedPreferences? _preferences;
  final List<BodyMeasurement> _items = [];

  List<BodyMeasurement> all() => List.unmodifiable(_items.reversed);

  void add({double? weightKg, double? waistCm, double? chestCm, double? hipCm, required String notes}) {
    _items.add(BodyMeasurement(
      id: 'measurement-${DateTime.now().microsecondsSinceEpoch}',
      recordedAt: DateTime.now(),
      weightKg: weightKg,
      waistCm: waistCm,
      chestCm: chestCm,
      hipCm: hipCm,
      notes: notes.trim(),
    ));
    _save();
  }

  void delete(String id) {
    _items.removeWhere((item) => item.id == id);
    _save();
  }

  void _restore() {
    final encoded = _preferences?.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) return;
    try {
      for (final raw in jsonDecode(encoded) as List<dynamic>) {
        final item = raw as Map<String, dynamic>;
        final recordedAt = DateTime.tryParse(item['recordedAt'] as String);
        if (recordedAt == null) continue;
        _items.add(BodyMeasurement(
          id: item['id'] as String,
          recordedAt: recordedAt,
          weightKg: (item['weightKg'] as num?)?.toDouble(),
          waistCm: (item['waistCm'] as num?)?.toDouble(),
          chestCm: (item['chestCm'] as num?)?.toDouble(),
          hipCm: (item['hipCm'] as num?)?.toDouble(),
          notes: item['notes'] as String? ?? '',
        ));
      }
    } on FormatException {}
  }

  void _save() => _preferences?.setString(
    _storageKey,
    jsonEncode(_items.map((item) => {
      'id': item.id, 'recordedAt': item.recordedAt.toIso8601String(), 'weightKg': item.weightKg,
      'waistCm': item.waistCm, 'chestCm': item.chestCm, 'hipCm': item.hipCm, 'notes': item.notes,
    }).toList(growable: false)),
  );
}
