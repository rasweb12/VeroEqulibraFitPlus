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
        onPressed: () => context.go('/nutrition/new'),
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

class NutritionMealFormPage extends ConsumerStatefulWidget {
  const NutritionMealFormPage({super.key});

  @override
  ConsumerState<NutritionMealFormPage> createState() =>
      _NutritionMealFormPageState();
}

class _NutritionMealFormPageState extends ConsumerState<NutritionMealFormPage> {
  final _name = TextEditingController();
  final _portion = TextEditingController();
  final _notes = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  String _mealType = 'Refeição';
  DateTime _recordedAt = DateTime.now();
  String? _estimateMessage;
  bool _estimating = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _portion,
      _notes,
      _calories,
      _protein,
      _carbs,
      _fat,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Voltar',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/nutrition'),
      ),
      title: const Text('Registrar refeição'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'O que você comeu?'),
        ),
        TextField(
          controller: _portion,
          decoration: const InputDecoration(
            labelText: 'Porção (ex.: 150 g, 1 unidade)',
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: _mealType,
          decoration: const InputDecoration(labelText: 'Momento'),
          items:
              const ['Café da manhã', 'Almoço', 'Lanche', 'Jantar', 'Refeição']
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(growable: false),
          onChanged: (value) => setState(() => _mealType = value!),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today_outlined),
          title: Text(
            'Data: ${MaterialLocalizations.of(context).formatMediumDate(_recordedAt)}',
          ),
          onTap: _pickDate,
        ),
        TextField(
          controller: _notes,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Observações (opcional)',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Informações nutricionais',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text(
          'Preencha manualmente ou peça uma sugestão ao Gemini. Todos os valores permanecem editáveis.',
        ),
        _numberField(_calories, 'Calorias (kcal)'),
        _numberField(_protein, 'Proteínas (g)'),
        _numberField(_carbs, 'Carboidratos (g)'),
        _numberField(_fat, 'Gorduras (g)'),
        if (_estimateMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_estimateMessage!),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _estimating ? null : _estimate,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: Text(_estimating ? 'Estimando…' : 'Estimar com Gemini'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Salvar refeição'),
        ),
      ],
    ),
  );

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (selected != null && mounted) setState(() => _recordedAt = selected);
  }

  Future<void> _estimate() async {
    if (_name.text.trim().length < 3) {
      setState(() => _estimateMessage = 'Informe o alimento antes de estimar.');
      return;
    }
    setState(() {
      _estimating = true;
      _estimateMessage = null;
    });
    try {
      final result = await ref
          .read(mealPhotoAnalysisRepositoryProvider)
          .estimateText(
            description: '${_name.text.trim()} ${_portion.text.trim()}'.trim(),
            mealType: _mealType,
          );
      if (!mounted) return;
      final items = result.items;
      _calories.text = items
          .fold<num>(0, (sum, item) => sum + item.calories)
          .toStringAsFixed(0);
      _protein.text = items
          .fold<num>(0, (sum, item) => sum + item.proteinGrams)
          .toStringAsFixed(1);
      _carbs.text = items
          .fold<num>(0, (sum, item) => sum + item.carbohydrateGrams)
          .toStringAsFixed(1);
      _fat.text = items
          .fold<num>(0, (sum, item) => sum + item.fatGrams)
          .toStringAsFixed(1);
      if (_portion.text.trim().isEmpty && items.isNotEmpty) {
        _portion.text = items
            .map((item) => '${item.portion} ${item.unit}')
            .join(', ');
      }
      setState(
        () => _estimateMessage =
            '${result.message} Ajuste os campos antes de salvar.',
      );
    } on Object {
      if (mounted) {
        setState(
          () => _estimateMessage =
              'Não foi possível estimar agora. Preencha os campos manualmente.',
        );
      }
    } finally {
      if (mounted) setState(() => _estimating = false);
    }
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe a refeição.')));
      return;
    }
    final portion = _portion.text.trim();
    final notes = _notes.text.trim();
    ref
        .read(mealsProvider.notifier)
        .add(
          name: _name.text,
          mealType: _mealType,
          notes: portion.isEmpty
              ? notes
              : notes.isEmpty
              ? 'Porção: $portion'
              : '$notes\nPorção: $portion',
          estimatedCalories: _number(_calories.text),
          proteinGrams: _number(_protein.text),
          carbohydrateGrams: _number(_carbs.text),
          fatGrams: _number(_fat.text),
          recordedAt: _recordedAt,
        );
    context.go('/nutrition');
  }

  Widget _numberField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      );

  double? _number(String value) => double.tryParse(value.replaceAll(',', '.'));
}
