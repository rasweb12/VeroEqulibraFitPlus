import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/owner_scope.dart';
import '../../../core/persistence/preferences_provider.dart';
import '../../../core/persistence/secure_owner_store.dart';
import '../../auth/presentation/current_owner_provider.dart';

@immutable
class NutritionGoals {
  const NutritionGoals({
    this.calories = 0,
    this.proteinGrams = 0,
    this.carbohydrateGrams = 0,
    this.fatGrams = 0,
    this.fiberGrams = 0,
  });
  final int calories;
  final int proteinGrams;
  final int carbohydrateGrams;
  final int fatGrams;
  final int fiberGrams;

  Map<String, int> toJson() => {
    'calories': calories,
    'proteinGrams': proteinGrams,
    'carbohydrateGrams': carbohydrateGrams,
    'fatGrams': fatGrams,
    'fiberGrams': fiberGrams,
  };

  factory NutritionGoals.fromJson(Map<String, dynamic> value) => NutritionGoals(
    calories: value['calories'] as int? ?? 0,
    proteinGrams: value['proteinGrams'] as int? ?? 0,
    carbohydrateGrams: value['carbohydrateGrams'] as int? ?? 0,
    fatGrams: value['fatGrams'] as int? ?? 0,
    fiberGrams: value['fiberGrams'] as int? ?? 0,
  );
}

class NutritionGoalsNotifier extends StateNotifier<NutritionGoals> {
  NutritionGoalsNotifier(this._ownerId, this._store) : super(const NutritionGoals()) {
    _restore();
  }
  final String _ownerId;
  final SecureOwnerStore _store;
  String get _key => ownerScopedKey(_ownerId, 'nutrition_goals_v1_secure');

  Future<void> _restore() async {
    final raw = await _store.read(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      if (mounted) state = NutritionGoals.fromJson(decoded);
    } on FormatException {
      // Corrupt local cache is ignored and never reassigned to another user.
    }
  }

  void save(NutritionGoals goals) {
    state = goals;
    unawaited(_store.write(_key, jsonEncode(goals.toJson())));
  }
}

final nutritionGoalsProvider = StateNotifierProvider.autoDispose<NutritionGoalsNotifier, NutritionGoals>(
  (ref) => NutritionGoalsNotifier(
    ref.watch(currentOwnerIdProvider),
    ref.read(secureOwnerStoreProvider),
  ),
);

class NutritionGoalsPage extends ConsumerStatefulWidget {
  const NutritionGoalsPage({super.key});
  @override
  ConsumerState<NutritionGoalsPage> createState() => _NutritionGoalsPageState();
}

class _NutritionGoalsPageState extends ConsumerState<NutritionGoalsPage> {
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _fiber = TextEditingController();
  bool _initialized = false;
  @override
  void dispose() { for (final item in [_calories, _protein, _carbs, _fat, _fiber]) { item.dispose(); } super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(nutritionGoalsProvider);
    if (!_initialized) {
      _initialized = true;
      _calories.text = goals.calories == 0 ? '' : goals.calories.toString();
      _protein.text = goals.proteinGrams == 0 ? '' : goals.proteinGrams.toString();
      _carbs.text = goals.carbohydrateGrams == 0 ? '' : goals.carbohydrateGrams.toString();
      _fat.text = goals.fatGrams == 0 ? '' : goals.fatGrams.toString();
      _fiber.text = goals.fiberGrams == 0 ? '' : goals.fiberGrams.toString();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Metas nutricionais')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Defina metas pessoais revisáveis. Estes valores orientam o diário e não substituem acompanhamento profissional.'),
        const SizedBox(height: 16),
        _field(_calories, 'Meta de calorias (kcal)'),
        _field(_protein, 'Meta de proteínas (g)'),
        _field(_carbs, 'Meta de carboidratos (g)'),
        _field(_fat, 'Meta de gorduras (g)'),
        _field(_fiber, 'Meta de fibras (g)'),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Salvar metas')),
      ]),
    );
  }
  Widget _field(TextEditingController controller, String label) => TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label));
  void _save() {
    int value(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;
    final goals = NutritionGoals(calories: value(_calories), proteinGrams: value(_protein), carbohydrateGrams: value(_carbs), fatGrams: value(_fat), fiberGrams: value(_fiber));
    if ([goals.calories, goals.proteinGrams, goals.carbohydrateGrams, goals.fatGrams, goals.fiberGrams].any((item) => item < 0)) return;
    ref.read(nutritionGoalsProvider.notifier).save(goals);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Metas salvas neste dispositivo.')));
  }
}
