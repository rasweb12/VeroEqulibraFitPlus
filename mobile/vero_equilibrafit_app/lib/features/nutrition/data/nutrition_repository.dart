import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/persistence/owner_scope.dart';

import '../domain/meal_entry.dart';

class NutritionRepository {
  NutritionRepository({required String ownerId, SharedPreferences? preferences})
    : _preferences = preferences,
      _storageKey = ownerScopedKey(ownerId, 'nutrition_repository_v2') {
    _restore();
  }
  final String _storageKey;
  final SharedPreferences? _preferences;
  final List<MealEntry> _entries = [];

  List<MealEntry> entries() => List.unmodifiable(_entries.reversed);

  void add({
    required String name,
    required String mealType,
    required String notes,
    double? estimatedCalories,
    double? proteinGrams,
    double? carbohydrateGrams,
    double? fatGrams,
  }) {
    _entries.add(MealEntry(
      id: 'meal-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      mealType: mealType,
      notes: notes.trim(),
      recordedAt: DateTime.now(),
      estimatedCalories: estimatedCalories,
      proteinGrams: proteinGrams,
      carbohydrateGrams: carbohydrateGrams,
      fatGrams: fatGrams,
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
          estimatedCalories: (entry['estimatedCalories'] as num?)?.toDouble(),
          proteinGrams: (entry['proteinGrams'] as num?)?.toDouble(),
          carbohydrateGrams: (entry['carbohydrateGrams'] as num?)?.toDouble(),
          fatGrams: (entry['fatGrams'] as num?)?.toDouble(),
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
      'estimatedCalories': entry.estimatedCalories,
      'proteinGrams': entry.proteinGrams,
      'carbohydrateGrams': entry.carbohydrateGrams,
      'fatGrams': entry.fatGrams,
    }).toList(growable: false)),
  );
}
