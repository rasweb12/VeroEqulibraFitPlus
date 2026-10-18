import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/app_drawer.dart';
import '../data/meal_photo_analysis_repository.dart';
import 'nutrition_providers.dart';
import '../domain/meal_entry.dart';

class NutritionPage extends ConsumerWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealsProvider);
    final selectedDay = ref.watch(nutritionDiaryDateProvider);
    final dayMeals = meals.where((meal) => _sameDay(meal.recordedAt, selectedDay)).toList(growable: false);
    final calories = dayMeals.fold<double>(0, (sum, meal) => sum + (meal.estimatedCalories ?? 0));
    final protein = dayMeals.fold<double>(0, (sum, meal) => sum + (meal.proteinGrams ?? 0));
    final carbs = dayMeals.fold<double>(0, (sum, meal) => sum + (meal.carbohydrateGrams ?? 0));
    final fat = dayMeals.fold<double>(0, (sum, meal) => sum + (meal.fatGrams ?? 0));
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
          IconButton(
            tooltip: 'Metas nutricionais',
            onPressed: () => context.go('/nutrition/goals'),
            icon: const Icon(Icons.track_changes_outlined),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/nutrition/new'),
        icon: const Icon(Icons.add),
        label: const Text('Registrar refeição'),
      ),
      body: Column(
        children: [
          _DiarySummary(
            selectedDay: selectedDay,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            onPrevious: () => ref.read(nutritionDiaryDateProvider.notifier).state = selectedDay.subtract(const Duration(days: 1)),
            onNext: selectedDay.isBefore(DateTime.now())
                ? () => ref.read(nutritionDiaryDateProvider.notifier).state = selectedDay.add(const Duration(days: 1))
                : null,
          ),
          Expanded(child: dayMeals.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.restaurant_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma refeição neste dia',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Registre uma refeição manualmente, por texto ou por foto. Estimativas sempre podem ser revisadas.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: dayMeals.length,
              itemBuilder: (context, index) {
                final meal = dayMeals[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.restaurant_outlined),
                    title: Text(meal.name),
                    subtitle: Text(
                      '${meal.mealType} · ${TimeOfDay.fromDateTime(meal.recordedAt).format(context)}${meal.estimatedCalories == null ? '' : '\n≈ ${meal.estimatedCalories!.round()} kcal · P ${meal.proteinGrams?.round() ?? 0} g · C ${meal.carbohydrateGrams?.round() ?? 0} g · G ${meal.fatGrams?.round() ?? 0} g'}${meal.notes.isEmpty ? '' : '\n${meal.notes}'}',
                    ),
                    isThreeLine:
                        meal.notes.isNotEmpty || meal.estimatedCalories != null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Editar registro',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              context.go('/nutrition/${meal.id}/edit'),
                        ),
                        IconButton(
                          tooltip: 'Excluir registro',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              ref.read(mealsProvider.notifier).delete(meal.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
    MealPhotoAnalysis result;
    try {
      result = await ref
          .read(mealPhotoAnalysisRepositoryProvider)
          .analyze(bytes: bytes, mimeType: mime);
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
    context.push(
      '/nutrition/photo-review',
      extra: PhotoMealReviewInput(
        imageBytes: bytes,
        message: result.message,
        items: result.items,
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

class _DiarySummary extends StatelessWidget {
  const _DiarySummary({required this.selectedDay, required this.calories, required this.protein, required this.carbs, required this.fat, required this.onPrevious, required this.onNext});
  final DateTime selectedDay;
  final double calories, protein, carbs, fat;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Row(children: [
          IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left), tooltip: 'Dia anterior'),
          Expanded(child: Text(MaterialLocalizations.of(context).formatMediumDate(selectedDay), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right), tooltip: 'Próximo dia'),
        ]),
        Text('≈ ${calories.round()} kcal registradas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Proteínas ${protein.round()} g  ·  Carboidratos ${carbs.round()} g  ·  Gorduras ${fat.round()} g'),
      ]),
    ),
  );
}

/// Dados efêmeros da análise: a imagem não é persistida neste objeto.
class PhotoMealReviewInput {
  const PhotoMealReviewInput({
    required this.imageBytes,
    required this.message,
    required this.items,
  });

  final Uint8List imageBytes;
  final String message;
  final List<MealPhotoItem> items;
}

class NutritionPhotoReviewPage extends ConsumerStatefulWidget {
  const NutritionPhotoReviewPage({super.key, required this.input});

  final PhotoMealReviewInput input;

  @override
  ConsumerState<NutritionPhotoReviewPage> createState() =>
      _NutritionPhotoReviewPageState();
}

class _NutritionPhotoReviewPageState
    extends ConsumerState<NutritionPhotoReviewPage> {
  late List<_PhotoFoodDraft> _items;
  DateTime _recordedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _items = widget.input.items.map(_PhotoFoodDraft.fromAnalysis).toList();
  }

  double get _calories => _items.fold(0, (sum, item) => sum + item.calories);
  double get _protein => _items.fold(0, (sum, item) => sum + item.protein);
  double get _carbs => _items.fold(0, (sum, item) => sum + item.carbs);
  double get _fat => _items.fold(0, (sum, item) => sum + item.fat);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar estimativa da foto')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              widget.input.imageBytes,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.input.message),
          const SizedBox(height: 8),
          const Text(
            'As porções e nutrientes são estimativas. Revise cada alimento antes de salvar.',
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Data e horário do registro'),
            subtitle: Text(
              MaterialLocalizations.of(context).formatFullDate(_recordedAt),
            ),
            trailing: TextButton(
              onPressed: _selectDate,
              child: const Text('Alterar'),
            ),
          ),
          Text(
            '≈ ${_calories.round()} kcal · P ${_protein.round()} g · C ${_carbs.round()} g · G ${_fat.round()} g',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < _items.length; index++)
            _foodEditor(index),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => _items.add(_PhotoFoodDraft.empty())),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar alimento'),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Confirmar e salvar refeição'),
          ),
        ],
      ),
    );
  }

  Widget _foodEditor(int index) {
    final item = _items[index];
    return Card(
      key: ValueKey(item.key),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Alimento ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Remover alimento',
                  onPressed: () => setState(() => _items.removeAt(index)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            TextFormField(
              initialValue: item.name,
              decoration: const InputDecoration(labelText: 'Nome do alimento'),
              onChanged: (value) => item.name = value,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  item.confidenceLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.portion.toString(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Porção'),
                    onChanged: (value) =>
                        setState(() => item.portion = _number(value)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: item.unit,
                    decoration: const InputDecoration(labelText: 'Unidade'),
                    onChanged: (value) => item.unit = value,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _macroField(
                    'kcal',
                    item.calories,
                    (value) => item.calories = value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _macroField(
                    'Proteína (g)',
                    item.protein,
                    (value) => item.protein = value,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _macroField(
                    'Carboidratos (g)',
                    item.carbs,
                    (value) => item.carbs = value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _macroField(
                    'Gorduras (g)',
                    item.fat,
                    (value) => item.fat = value,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroField(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) => TextFormField(
    initialValue: value.toString(),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
    onChanged: (text) => setState(() => onChanged(_number(text))),
  );

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _recordedAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _recordedAt.hour,
        _recordedAt.minute,
      );
    });
  }

  void _save() {
    final validItems = _items
        .where((item) => item.name.trim().isNotEmpty)
        .toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione ao menos um alimento para salvar.'),
        ),
      );
      return;
    }
    ref
        .read(mealsProvider.notifier)
        .add(
          name: validItems
              .map(
                (item) =>
                    '${item.name.trim()} (${item.portion} ${item.unit.trim()})',
              )
              .join(', '),
          mealType: 'Refeição',
          notes: 'Estimativa por foto revisada pelo usuário.',
          recordedAt: _recordedAt,
          estimatedCalories: _calories,
          proteinGrams: _protein,
          carbohydrateGrams: _carbs,
          fatGrams: _fat,
        );
    context.go('/nutrition');
  }

  double _number(String value) =>
      double.tryParse(value.replaceAll(',', '.')) ?? 0;
}

class _PhotoFoodDraft {
  _PhotoFoodDraft({
    required this.key,
    required this.name,
    required this.portion,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.confidence,
  });

  factory _PhotoFoodDraft.fromAnalysis(MealPhotoItem item) => _PhotoFoodDraft(
    key: Object(),
    name: item.name,
    portion: item.portion.toDouble(),
    unit: item.unit,
    calories: item.calories.toDouble(),
    protein: item.proteinGrams.toDouble(),
    carbs: item.carbohydrateGrams.toDouble(),
    fat: item.fatGrams.toDouble(),
    confidence: item.confidence.toDouble(),
  );

  factory _PhotoFoodDraft.empty() => _PhotoFoodDraft(
    key: Object(),
    name: '',
    portion: 1,
    unit: 'porção',
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    confidence: 0,
  );

  final Object key;
  String name;
  double portion;
  String unit;
  double calories;
  double protein;
  double carbs;
  double fat;
  double confidence;

  String get confidenceLabel {
    if (confidence >= .8) return 'Confiança da identificação: alta. Ainda revise porção e preparo.';
    if (confidence >= .5) return 'Confiança da identificação: moderada. Revise este alimento antes de salvar.';
    return 'Confiança da identificação: baixa. Confirme ou substitua este alimento antes de salvar.';
  }
}

class NutritionMealFormPage extends ConsumerStatefulWidget {
  const NutritionMealFormPage({super.key, this.mealId});
  final String? mealId;

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
  MealEntry? _existing;

  @override
  void initState() {
    super.initState();
    final mealId = widget.mealId;
    if (mealId == null) return;
    for (final meal in ref.read(mealsProvider)) {
      if (meal.id != mealId) continue;
      _existing = meal;
      _name.text = meal.name;
      _notes.text = meal.notes;
      _mealType = meal.mealType;
      _recordedAt = meal.recordedAt;
      _calories.text = meal.estimatedCalories?.toString() ?? '';
      _protein.text = meal.proteinGrams?.toString() ?? '';
      _carbs.text = meal.carbohydrateGrams?.toString() ?? '';
      _fat.text = meal.fatGrams?.toString() ?? '';
      break;
    }
  }

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
      title: Text(_existing == null ? 'Registrar refeição' : 'Editar refeição'),
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
          label: Text(
            _existing == null ? 'Salvar refeição' : 'Salvar alterações',
          ),
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
    final controller = ref.read(mealsProvider.notifier);
    final existing = _existing;
    final savedNotes = portion.isEmpty
        ? notes
        : notes.isEmpty
        ? 'Porção: $portion'
        : '$notes\nPorção: $portion';
    if (existing == null) {
      controller.add(
        name: _name.text,
        mealType: _mealType,
        notes: savedNotes,
        estimatedCalories: _number(_calories.text),
        proteinGrams: _number(_protein.text),
        carbohydrateGrams: _number(_carbs.text),
        fatGrams: _number(_fat.text),
        recordedAt: _recordedAt,
      );
    } else {
      controller.update(
        existing.copyWith(
          name: _name.text.trim(),
          mealType: _mealType,
          notes: savedNotes,
          estimatedCalories: _number(_calories.text),
          proteinGrams: _number(_protein.text),
          carbohydrateGrams: _number(_carbs.text),
          fatGrams: _number(_fat.text),
          recordedAt: _recordedAt,
        ),
      );
    }
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
