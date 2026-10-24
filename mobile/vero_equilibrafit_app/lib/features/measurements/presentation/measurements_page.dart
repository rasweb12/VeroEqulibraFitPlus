import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/app_drawer.dart';
import '../../../shared/presentation/vero_design.dart';
import '../domain/body_measurement.dart';
import '../domain/measurement_selectors.dart';
import 'measurements_providers.dart';

class MeasurementsPage extends ConsumerWidget {
  const MeasurementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(measurementsProvider);
    final current = latestWeightMeasurement(entries)?.weightKg;
    final change = weightChangeAcrossHistory(entries);
    final weights = chronologicalWeightMeasurements(entries);
    return Scaffold(
      backgroundColor: VeroColors.background,
      appBar: AppBar(
        backgroundColor: VeroColors.surface,
        surfaceTintColor: VeroColors.surface,
        elevation: 0,
        title: const Text(
          'Evolução corporal',
          style: TextStyle(fontWeight: FontWeight.w800, color: VeroColors.text),
        ),
        leading: Builder(
          builder: (scaffoldContext) => IconButton(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu_rounded, color: VeroColors.text),
            onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
          ),
        ),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const VeroBottomNavigation(
        location: '/measurements',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar medida'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          _SummaryCard(
            current: current,
            change: change,
            records: entries.length,
          ),
          const SizedBox(height: 16),
          WeightTrendCard(weights: weights),
          const SizedBox(height: 20),
          const Text(
            'Histórico de medições',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('Ainda não há medições.')),
            )
          else
            ...entries.map(
              (entry) => _MeasurementTile(
                entry: entry,
                onEdit: () => _edit(context, ref, entry),
                onDelete: () => _confirmDelete(context, ref, entry.id),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final draft = await showDialog<_MeasurementDraft>(
      context: context,
      builder: (_) => const _MeasurementEditorDialog(),
    );
    await _afterDialogFrame();
    if (draft == null || !context.mounted) return;
    try {
      await ref
          .read(measurementsProvider.notifier)
          .add(
            recordedAt: draft.recordedAt,
            weightKg: draft.weightKg,
            waistCm: draft.waistCm,
            chestCm: draft.chestCm,
            hipCm: draft.hipCm,
            notes: draft.notes,
          );
      if (context.mounted) _message(context, 'Medida salva.');
    } catch (_) {
      if (context.mounted) {
        _message(
          context,
          'Não foi possível salvar a medida. Tente novamente.',
          error: true,
        );
      }
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    BodyMeasurement entry,
  ) async {
    final draft = await showDialog<_MeasurementDraft>(
      context: context,
      builder: (_) => _MeasurementEditorDialog(entry: entry),
    );
    await _afterDialogFrame();
    if (draft == null || !context.mounted) return;
    try {
      await ref
          .read(measurementsProvider.notifier)
          .update(
            entry,
            recordedAt: draft.recordedAt,
            weightKg: draft.weightKg,
            waistCm: draft.waistCm,
            chestCm: draft.chestCm,
            hipCm: draft.hipCm,
            notes: draft.notes,
          );
      if (context.mounted) _message(context, 'Medida atualizada.');
    } catch (_) {
      if (context.mounted) {
        _message(
          context,
          'Não foi possível atualizar a medida. Tente novamente.',
          error: true,
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: const Text('Excluir registro?'),
            content: const Text(
              'Esta ação remove somente esta medição do histórico deste aparelho.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialog, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ) ??
        false;
    await _afterDialogFrame();
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(measurementsProvider.notifier).delete(id);
      if (context.mounted) _message(context, 'Registro excluído.');
    } catch (_) {
      if (context.mounted) {
        _message(
          context,
          'Não foi possível excluir o registro. Tente novamente.',
          error: true,
        );
      }
    }
  }

  void _message(BuildContext context, String text, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: error ? Colors.red.shade700 : null,
        ),
      );

  Future<void> _afterDialogFrame() async {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
    await completer.future;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.current,
    required this.change,
    required this.records,
  });
  final double? current;
  final double? change;
  final int records;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xffF1F5F9)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ÚLTIMO PESO REGISTRADO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: VeroColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                current == null
                    ? 'Sem peso'
                    : '${current!.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              change == null
                  ? 'Sem comparação'
                  : '${change! >= 0 ? '+' : ''}${change!.toStringAsFixed(1)} kg no período',
              style: const TextStyle(fontSize: 12, color: VeroColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          records == 0
              ? 'Registre peso ou medidas quando fizer sentido para você.'
              : '$records registro(s) no histórico.',
          style: const TextStyle(color: VeroColors.muted),
        ),
      ],
    ),
  );
}

class _MeasurementTile extends StatelessWidget {
  const _MeasurementTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });
  final BodyMeasurement entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final values = <String>[
      if (entry.weightKg != null) '${entry.weightKg!.toStringAsFixed(1)} kg',
      if (entry.waistCm != null)
        'Cintura ${entry.waistCm!.toStringAsFixed(1)} cm',
      if (entry.chestCm != null)
        'Peito ${entry.chestCm!.toStringAsFixed(1)} cm',
      if (entry.hipCm != null) 'Quadril ${entry.hipCm!.toStringAsFixed(1)} cm',
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffF1F5F9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: VeroColors.primary.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.monitor_weight_outlined,
            color: VeroColors.primary,
          ),
        ),
        title: Text(
          values.isEmpty ? 'Registro de evolução' : values.join(' · '),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${MaterialLocalizations.of(context).formatShortDate(entry.recordedAt)}${entry.notes.isEmpty ? '' : '\n${entry.notes}'}',
        ),
        isThreeLine: entry.notes.isNotEmpty,
        trailing: PopupMenuButton<_MeasureAction>(
          tooltip: 'Opções do registro',
          onSelected: (action) =>
              action == _MeasureAction.edit ? onEdit() : onDelete(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: _MeasureAction.edit, child: Text('Editar')),
            PopupMenuItem(value: _MeasureAction.delete, child: Text('Excluir')),
          ],
        ),
      ),
    );
  }
}

class _MeasurementEditorDialog extends StatefulWidget {
  const _MeasurementEditorDialog({this.entry});
  final BodyMeasurement? entry;
  @override
  State<_MeasurementEditorDialog> createState() =>
      _MeasurementEditorDialogState();
}

class _MeasurementEditorDialogState extends State<_MeasurementEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weight;
  late final TextEditingController _waist;
  late final TextEditingController _chest;
  late final TextEditingController _hip;
  late final TextEditingController _notes;
  late DateTime _recordedAt;
  String? _contentError;
  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _recordedAt = DateUtils.dateOnly(entry?.recordedAt ?? DateTime.now());
    _weight = TextEditingController(text: entry?.weightKg?.toString() ?? '');
    _waist = TextEditingController(text: entry?.waistCm?.toString() ?? '');
    _chest = TextEditingController(text: entry?.chestCm?.toString() ?? '');
    _hip = TextEditingController(text: entry?.hipCm?.toString() ?? '');
    _notes = TextEditingController(text: entry?.notes ?? '');
  }

  @override
  void dispose() {
    _weight.dispose();
    _waist.dispose();
    _chest.dispose();
    _hip.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.entry == null ? 'Registrar evolução' : 'Editar evolução',
    ),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                'Data: ${MaterialLocalizations.of(context).formatMediumDate(_recordedAt)}',
              ),
              onPressed: _selectDate,
            ),
            const SizedBox(height: 4),
            const Text(
              'Datas futuras não são permitidas.',
              style: TextStyle(fontSize: 12, color: VeroColors.muted),
            ),
            _metricField(_weight, 'Peso (kg)'),
            _metricField(_waist, 'Cintura (cm)'),
            _metricField(_chest, 'Peito (cm)'),
            _metricField(_hip, 'Quadril (cm)'),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
              ),
            ),
            if (_contentError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _contentError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Salvar')),
    ],
  );
  Widget _metricField(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: (value) => _validateMetric(value, label),
      );
  String? _validateMetric(String? value, String label) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null) return '$label deve ser um número válido.';
    if (parsed <= 0) return '$label deve ser maior que zero.';
    return null;
  }

  double? _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(1900),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );
    if (picked != null && mounted) {
      setState(() => _recordedAt = DateUtils.dateOnly(picked));
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final metrics = [
      _parse(_weight),
      _parse(_waist),
      _parse(_chest),
      _parse(_hip),
    ];
    if (metrics.every((value) => value == null) && _notes.text.trim().isEmpty) {
      setState(
        () => _contentError = 'Informe ao menos uma medida ou uma observação.',
      );
      return;
    }
    Navigator.pop(
      context,
      _MeasurementDraft(
        recordedAt: _recordedAt,
        weightKg: metrics[0],
        waistCm: metrics[1],
        chestCm: metrics[2],
        hipCm: metrics[3],
        notes: _notes.text.trim(),
      ),
    );
  }
}

class _MeasurementDraft {
  const _MeasurementDraft({
    required this.recordedAt,
    required this.weightKg,
    required this.waistCm,
    required this.chestCm,
    required this.hipCm,
    required this.notes,
  });
  final DateTime recordedAt;
  final double? weightKg;
  final double? waistCm;
  final double? chestCm;
  final double? hipCm;
  final String notes;
}

class WeightTrendCard extends StatelessWidget {
  const WeightTrendCard({super.key, required this.weights});
  final List<BodyMeasurement> weights;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xffF1F5F9)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evolução do peso',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 4),
        if (weights.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                'Registre um peso para visualizar sua evolução.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          SizedBox(
            height: 164,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (_, constraints) => CustomPaint(
                painter: _WeightChartPainter(
                  weights,
                  Theme.of(context).colorScheme.primary,
                ),
                size: Size(constraints.maxWidth, 164),
              ),
            ),
          ),
          Text(
            weights.length == 1
                ? 'Adicione outra medição de peso para comparar a evolução.'
                : 'Pontos representam registros reais nas respectivas datas.',
            style: const TextStyle(fontSize: 12, color: VeroColors.muted),
          ),
        ],
      ],
    ),
  );
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter(this.items, this.color);
  final List<BodyMeasurement> items;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final values = items.map((e) => e.weightKg!).toList();
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    const top = 18.0, bottom = 30.0, left = 38.0, right = 8.0;
    final chartH = size.height - top - bottom,
        chartW = size.width - left - right;
    final low = max == min ? min - .5 : min, high = max == min ? max + .5 : max;
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final grid = Paint()
      ..color = const Color(0xffE2E8F0)
      ..strokeWidth = 1;
    for (final fraction in [0.0, .5, 1.0]) {
      final y = top + chartH * fraction;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), grid);
    }
    final points = <Offset>[];
    for (var i = 0; i < items.length; i++) {
      final x = items.length == 1
          ? left + chartW / 2
          : left + chartW * i / (items.length - 1);
      points.add(
        Offset(x, top + chartH * ((high - items[i].weightKg!) / (high - low))),
      );
    }
    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, line);
    }
    final dot = Paint()..color = color;
    for (final point in points) {
      canvas.drawCircle(point, 4, dot);
    }
    _label(canvas, '${max.toStringAsFixed(1)} kg', Offset(0, top - 7));
    _label(canvas, '${min.toStringAsFixed(1)} kg', Offset(0, top + chartH - 7));
    _label(
      canvas,
      _date(items.first.recordedAt),
      Offset(left, size.height - 18),
    );
    if (items.length > 1) {
      _label(
        canvas,
        _date(items.last.recordedAt),
        Offset(size.width - right - 42, size.height - 18),
      );
    }
  }

  void _label(Canvas canvas, String value, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(fontSize: 10, color: VeroColors.muted),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 58);
    painter.paint(canvas, offset);
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  @override
  bool shouldRepaint(covariant _WeightChartPainter old) =>
      old.items != items || old.color != color;
}

enum _MeasureAction { edit, delete }
