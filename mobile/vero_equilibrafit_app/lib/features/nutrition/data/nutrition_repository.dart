import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/meal_entry.dart';

class NutritionRepository {
  NutritionRepository({SharedPreferences? preferences}) : _preferences = preferences {
    _restore();
  }
  static const _storageKey = 'nutrition_repository_v1';
  final SharedPreferences? _preferences;
  final List<MealEntry> _entries = [];

  List<MealEntry> entries() => List.unmodifiable(_entries.reversed);

  void add({
    required String name,
    required String mealType,
    required String notes,
  }) {
    _entries.add(MealEntry(
      id: 'meal-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      mealType: mealType,
      notes: notes.trim(),
      recordedAt: DateTime.now(),
    ));
    _save();
  }

  void delete(String id) {
    _entries.removeWhere((entry) => entry.id == id);
    _save();
  }

  void _restore() {
    final encoded = _preferences?.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) return;
    try {
      final entries = jsonDecode(encoded) as List<dynamic>;
      for (final item in entries) {
        final entry = item as Map<String, dynamic>;
        final recordedAt = DateTime.tryParse(entry['recordedAt'] as String);
        if (recordedAt == null) continue;
        _entries.add(MealEntry(
          id: entry['id'] as String,
          name: entry['name'] as String,
          mealType: entry['mealType'] as String,
          notes: entry['notes'] as String? ?? '',
          recordedAt: recordedAt,
        ));
      }
    } on FormatException {
      // Ignore only the local cache if it cannot be decoded.
    }
  }

  void _save() => _preferences?.setString(
    _storageKey,
    jsonEncode(_entries.map((entry) => {
      'id': entry.id,
      'name': entry.name,
      'mealType': entry.mealType,
      'notes': entry.notes,
      'recordedAt': entry.recordedAt.toIso8601String(),
    }).toList(growable: false)),
  );
}
