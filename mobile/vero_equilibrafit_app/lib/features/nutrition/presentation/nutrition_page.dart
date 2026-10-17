import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/app_drawer.dart';
import 'nutrition_providers.dart';

class NutritionPage extends ConsumerWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alimentação'),
        actions: [
          IconButton(
            tooltip: 'Analisar foto da refeição',
            onPressed: () => _pickAndAnalyzePhoto(context, ref),
            icon: const Icon(Icons.camera_alt_outlined),
          ),
          IconButton(
            tooltip: 'Plano alimentar',
            onPressed: () => context.go('/nutrition/plans'),
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMeal(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar refeição'),
      ),
      body: meals.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.restaurant_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Registre sua primeira refeição',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use um registro simples agora e complemente com análise pelo Coach quando o serviço estiver configurado.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: meals.length,
              itemBuilder: (context, index) {
                final meal = meals[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.restaurant_outlined),
                    title: Text(meal.name),
                    subtitle: Text(
                      '${meal.mealType} · ${TimeOfDay.fromDateTime(meal.recordedAt).format(context)}${meal.estimatedCalories == null ? '' : '\n≈ ${meal.estimatedCalories!.round()} kcal · P ${meal.proteinGrams?.round() ?? 0} g · C ${meal.carbohydrateGrams?.round() ?? 0} g · G ${meal.fatGrams?.round() ?? 0} g'}${meal.notes.isEmpty ? '' : '\n${meal.notes}'}',
                    ),
                    isThreeLine:
                        meal.notes.isNotEmpty || meal.estimatedCalories != null,
                    trailing: IconButton(
                      tooltip: 'Excluir registro',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          ref.read(mealsProvider.notifier).delete(meal.id),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _addMeal(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final notes = TextEditingController();
    final portion = TextEditingController();
    final calories = TextEditingController();
    final protein = TextEditingController();
    final carbs = TextEditingController();
    final fat = TextEditingController();
    var mealType = 'Refeição';
    var recordedAt = DateTime.now();
    final action = await showDialog<_ManualMealAction>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Registrar refeição'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'O que você comeu?',
                  ),
                ),
                TextField(
                  controller: portion,
                  decoration: const InputDecoration(
                    labelText: 'Porção (ex.: 150 g, 1 unidade)',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                    'Data: ${MaterialLocalizations.of(context).formatMediumDate(recordedAt)}',
                  ),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDate: recordedAt,
                    );
                    if (selected != null) setState(() => recordedAt = selected);
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: mealType,
                  decoration: const InputDecoration(labelText: 'Momento'),
                  items:
                      const [
                            'Café da manhã',
                            'Almoço',
                            'Lanche',
                            'Jantar',
                            'Refeição',
                          ]
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(growable: false),
                  onChanged: (value) => setState(() => mealType = value!),
                ),
                TextField(
                  controller: notes,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Preencha estes campos para salvar sem estimativa.'),
                _numberField(calories, 'Calorias (kcal)'),
                _numberField(protein, 'Proteínas (g)'),
                _numberField(carbs, 'Carboidratos (g)'),
                _numberField(fat, 'Gorduras (g)'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _ManualMealAction.save),
              child: const Text('Salvar sem estimativa'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _ManualMealAction.estimate),
              child: const Text('Estimar com Gemini'),
            ),
          ],
        ),
      ),
    );
    if (action != null && name.text.trim().isNotEmpty && context.mounted) {
      if (action == _ManualMealAction.save) {
        ref
            .read(mealsProvider.notifier)
            .add(
              name: name.text,
              mealType: mealType,
              notes: _notesWithPortion(notes.text, portion.text),
              estimatedCalories: _number(calories.text),
              proteinGrams: _number(protein.text),
              carbohydrateGrams: _number(carbs.text),
              fatGrams: _number(fat.text),
              recordedAt: recordedAt,
            );
      } else {
        await _estimateManualMeal(
          context,
          ref,
          name.text.trim(),
          mealType,
          _notesWithPortion(notes.text, portion.text),
          recordedAt,
        );
      }
    }
    name.dispose();
    notes.dispose();
    for (final controller in [portion, calories, protein, carbs, fat]) {
      controller.dispose();
    }
  }

  Future<void> _estimateManualMeal(
    BuildContext context,
    WidgetRef ref,
    String description,
    String mealType,
    String notes,
    DateTime recordedAt,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Estimando informações nutricionais com Gemini…'),
      ),
    );
    try {
      final result = await ref
          .read(mealPhotoAnalysisRepositoryProvider)
          .estimateText(description: description, mealType: mealType);
      if (!context.mounted) return;
      final calories = result.items.fold<num>(
        0,
        (sum, item) => sum + item.calories,
      );
      final protein = result.items.fold<num>(
        0,
        (sum, item) => sum + item.proteinGrams,
      );
      final carbs = result.items.fold<num>(
        0,
        (sum, item) => sum + item.carbohydrateGrams,
      );
      final fat = result.items.fold<num>(0, (sum, item) => sum + item.fatGrams);
      await _reviewManualEstimate(
        context,
        ref,
        name: description,
        mealType: mealType,
        notes: notes,
        recordedAt: recordedAt,
        message: result.message,
        calories: calories.toDouble(),
        protein: protein.toDouble(),
        carbs: carbs.toDouble(),
        fat: fat.toDouble(),
      );
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível estimar agora. Você pode salvar manualmente.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _reviewManualEstimate(
    BuildContext context,
    WidgetRef ref, {
    required String name,
    required String mealType,
    required String notes,
    required DateTime recordedAt,
    required String message,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    final kcal = TextEditingController(text: calories.toStringAsFixed(0));
    final proteinField = TextEditingController(
      text: protein.toStringAsFixed(1),
    );
    final carbsField = TextEditingController(text: carbs.toStringAsFixed(1));
    final fatField = TextEditingController(text: fat.toStringAsFixed(1));
    final accept = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revisar estimativa nutricional'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 8),
              const Text(
                'Valores estimados, não medidos. Ajuste antes de aceitar.',
              ),
              _numberField(kcal, 'Calorias (kcal)'),
              _numberField(proteinField, 'Proteínas (g)'),
              _numberField(carbsField, 'Carboidratos (g)'),
              _numberField(fatField, 'Gorduras (g)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Aceitar e salvar'),
          ),
        ],
      ),
    );
    if (accept == true && context.mounted) {
      ref
          .read(mealsProvider.notifier)
          .add(
            name: name,
            mealType: mealType,
            notes: notes.isEmpty
                ? 'Estimativa Gemini revisada pelo usuário.'
                : '$notes\nEstimativa Gemini revisada pelo usuário.',
            estimatedCalories: _number(kcal.text),
            proteinGrams: _number(proteinField.text),
            carbohydrateGrams: _number(carbsField.text),
            fatGrams: _number(fatField.text),
            recordedAt: recordedAt,
          );
    }
    for (final controller in [kcal, proteinField, carbsField, fatField]) {
      controller.dispose();
    }
  }

  Widget _numberField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      );

  double? _number(String value) => double.tryParse(value.replaceAll(',', '.'));

  String _notesWithPortion(String notes, String portion) {
    final normalized = portion.trim();
    if (normalized.isEmpty) return notes.trim();
    return notes.trim().isEmpty
        ? 'Porção: $normalized'
        : '${notes.trim()}\nPorção: $normalized';
  }

  Future<void> _pickAndAnalyzePhoto(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Fotografar refeição'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (file == null || !context.mounted) {
      return;
    }
    final bytes = await file.readAsBytes();
    final mime = file.mimeType ?? _mimeFromPath(file.path);
    if (!const {'image/jpeg', 'image/png', 'image/webp'}.contains(mime)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Use uma imagem JPEG, PNG ou WebP.')),
        );
      }
      return;
    }
    if (bytes.length > 5 * 1024 * 1024) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A foto deve ter até 5 MB.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    await _reviewPhoto(context, ref, bytes, mime);
  }

  Future<void> _reviewPhoto(
    BuildContext context,
    WidgetRef ref,
    Uint8List bytes,
    String mime,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analisando foto com Gemini…')),
    );
    List<String> suggestions;
    double calories = 0, protein = 0, carbs = 0, fat = 0;
    String message;
    try {
      final result = await ref
          .read(mealPhotoAnalysisRepositoryProvider)
          .analyze(bytes: bytes, mimeType: mime);
      suggestions = result.items
          .map((item) => '${item.name} — ${item.portion} ${item.unit}')
          .toList(growable: false);
      calories = result.items.fold(
        0,
        (sum, item) => sum + item.calories.toDouble(),
      );
      protein = result.items.fold(
        0,
        (sum, item) => sum + item.proteinGrams.toDouble(),
      );
      carbs = result.items.fold(
        0,
        (sum, item) => sum + item.carbohydrateGrams.toDouble(),
      );
      fat = result.items.fold(0, (sum, item) => sum + item.fatGrams.toDouble());
      message = result.message;
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível analisar esta foto. Registre manualmente.',
            ),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revisar estimativa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(bytes, height: 150, fit: BoxFit.cover),
              const SizedBox(height: 12),
              Text(
                '$message\n\n≈ ${calories.round()} kcal · P ${protein.round()} g · C ${carbs.round()} g · G ${fat.round()} g\nValores estimados, não medidos.',
              ),
              ...suggestions.map((item) => ListTile(title: Text(item))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(mealsProvider.notifier)
                  .add(
                    name: suggestions.isEmpty
                        ? 'Refeição revisada'
                        : suggestions.join(', '),
                    mealType: 'Refeição',
                    notes: 'Estimativa por foto revisada pelo usuário.',
                    estimatedCalories: calories,
                    proteinGrams: protein,
                    carbohydrateGrams: carbs,
                    fatGrams: fat,
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('Confirmar e salvar'),
          ),
        ],
      ),
    );
  }

  String _mimeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

enum _ManualMealAction { save, estimate }
