import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/owner_scope.dart';
import '../../../core/persistence/preferences_provider.dart';
import '../../../core/persistence/secure_owner_store.dart';
import '../../auth/presentation/current_owner_provider.dart';
import '../../../shared/presentation/app_drawer.dart';

@immutable
class HabitEntry {
  const HabitEntry({
    required this.kind,
    required this.value,
    required this.at,
    this.detail = '',
  });
  final String kind;
  final int value;
  final DateTime at;
  final String detail;
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'value': value,
    'at': at.toUtc().toIso8601String(),
    'detail': detail,
  };
  static HabitEntry? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final kind = raw['kind'] as String?;
    final value = raw['value'] as int?;
    final at = DateTime.tryParse(raw['at'] as String? ?? '');
    if (kind == null || value == null || at == null) return null;
    return HabitEntry(
      kind: kind,
      value: value,
      at: at.toLocal(),
      detail: raw['detail'] as String? ?? '',
    );
  }
}

bool sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

@immutable
class HabitsState {
  const HabitsState({
    this.entries = const [],
    this.waterGoalMl = 2000,
    this.mobilityDone = false,
  });
  final List<HabitEntry> entries;
  final int waterGoalMl;
  final bool mobilityDone;
  int get waterMl => entries
      .where(
        (entry) => entry.kind == 'water' && sameDay(entry.at, DateTime.now()),
      )
      .fold(0, (sum, entry) => sum + entry.value);
  bool get hasActivityToday => entries.any(
    (entry) => entry.kind == 'activity' && sameDay(entry.at, DateTime.now()),
  );
  bool get hasNoteToday => entries.any(
    (entry) => entry.kind == 'note' && sameDay(entry.at, DateTime.now()),
  );
  HabitsState copyWith({
    List<HabitEntry>? entries,
    int? waterGoalMl,
    bool? mobilityDone,
  }) => HabitsState(
    entries: entries ?? this.entries,
    waterGoalMl: waterGoalMl ?? this.waterGoalMl,
    mobilityDone: mobilityDone ?? this.mobilityDone,
  );
}

class HabitsNotifier extends StateNotifier<HabitsState> {
  HabitsNotifier(this._store, {required String ownerId})
    : _key = ownerScopedKey(ownerId, 'habits_v4_secure'),
      super(const HabitsState()) {
    _restore();
  }
  final SecureOwnerStore _store;
  final String _key;
  Future<void> _restore() async {
    final raw =
        await _store.read(_key) ??
        await _store.read(_key.replaceFirst('v4', 'v3'));
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final entries = (map['entries'] as List<dynamic>? ?? const [])
          .map(HabitEntry.fromJson)
          .whereType<HabitEntry>()
          .toList();
      if (entries.isEmpty) {
        for (final milliliters
            in map['waterRecords'] as List<dynamic>? ?? const []) {
          if (milliliters is int && milliliters > 0) {
            entries.add(
              HabitEntry(kind: 'water', value: milliliters, at: DateTime.now()),
            );
          }
        }
      }
      if (mounted) {
        state = HabitsState(
          entries: entries,
          waterGoalMl: map['waterGoalMl'] as int? ?? 2000,
          mobilityDone: map['mobilityDone'] as bool? ?? false,
        );
      }
    } on FormatException {
      /* Leave unreadable owner-scoped cache untouched. */
    }
  }

  void addWater([int ml = 250]) {
    if (ml < 1 || ml > 2000) return;
    _append(HabitEntry(kind: 'water', value: ml, at: DateTime.now()));
  }

  void addActivity(String name, int minutes, String notes) {
    if (name.trim().isEmpty || minutes < 1 || minutes > 1440) return;
    _append(
      HabitEntry(
        kind: 'activity',
        value: minutes,
        at: DateTime.now(),
        detail: '${name.trim()}\n${notes.trim()}',
      ),
    );
  }

  void addNote(String note) {
    if (note.trim().isEmpty || note.trim().length > 2000) return;
    _append(
      HabitEntry(
        kind: 'note',
        value: 1,
        at: DateTime.now(),
        detail: note.trim(),
      ),
    );
  }

  void setWaterGoal(int ml) {
    if (ml < 250 || ml > 10000) return;
    state = state.copyWith(waterGoalMl: ml);
    unawaited(_save());
  }

  void setMobility(bool done) {
    state = state.copyWith(mobilityDone: done);
    unawaited(_save());
  }

  void _append(HabitEntry item) {
    state = state.copyWith(entries: [...state.entries, item]);
    unawaited(_save());
  }

  Future<void> _save() => _store.write(
    _key,
    jsonEncode({
      'entries': state.entries.map((entry) => entry.toJson()).toList(),
      'waterGoalMl': state.waterGoalMl,
      'mobilityDone': state.mobilityDone,
    }),
  );
}

final habitsProvider =
    StateNotifierProvider.autoDispose<HabitsNotifier, HabitsState>(
      (ref) => HabitsNotifier(
        ref.read(secureOwnerStoreProvider),
        ownerId: ref.watch(currentOwnerIdProvider),
      ),
    );

class HabitsPage extends ConsumerWidget {
  const HabitsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hábitos e hidratação')),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Registre o que fez hoje, no seu ritmo.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.water_drop_outlined),
              title: const Text('Hidratação'),
              subtitle: Text(
                '${state.waterMl} ml de ${state.waterGoalMl} ml hoje',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.tune_outlined),
                tooltip: 'Ajustar meta',
                onPressed: () => _waterGoal(context, ref, state.waterGoalMl),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [150, 200, 250, 300, 500]
                .map(
                  (ml) => OutlinedButton(
                    onPressed: () =>
                        ref.read(habitsProvider.notifier).addWater(ml),
                    child: Text('+$ml ml'),
                  ),
                )
                .toList(),
          ),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.self_improvement_outlined),
              title: const Text('Mobilidade'),
              subtitle: const Text('Marque quando concluir sua prática.'),
              value: state.mobilityDone,
              onChanged: ref.read(habitsProvider.notifier).setMobility,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_run_outlined),
              title: const Text('Atividade'),
              subtitle: Text(
                state.hasActivityToday
                    ? 'Atividade registrada hoje'
                    : 'Registre duração e observações.',
              ),
              trailing: const Icon(Icons.add),
              onTap: () => _activity(context, ref),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.note_alt_outlined),
              title: const Text('Anotação do dia'),
              subtitle: Text(
                state.hasNoteToday
                    ? 'Anotação registrada hoje'
                    : 'Registre algo que queira lembrar.',
              ),
              trailing: const Icon(Icons.add),
              onTap: () => _note(context, ref),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Atividades e anotações ficam protegidas neste aparelho. Elas não são enviadas ao Coach automaticamente.',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _waterGoal(
    BuildContext context,
    WidgetRef ref,
    int value,
  ) async {
    final text = TextEditingController(text: '$value');
    final result = await _dialog(context, 'Meta diária de água', [
      TextField(
        controller: text,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Volume em ml'),
      ),
    ]);
    if (result) {
      ref
          .read(habitsProvider.notifier)
          .setWaterGoal(int.tryParse(text.text) ?? 0);
    }
    text.dispose();
  }

  Future<void> _activity(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController(text: 'Caminhada');
    final minutes = TextEditingController();
    final note = TextEditingController();
    final result = await _dialog(context, 'Registrar atividade', [
      TextField(
        controller: name,
        decoration: const InputDecoration(labelText: 'Atividade'),
      ),
      TextField(
        controller: minutes,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Duração em minutos'),
      ),
      TextField(
        controller: note,
        maxLines: 2,
        decoration: const InputDecoration(labelText: 'Observação opcional'),
      ),
    ]);
    if (result) {
      ref
          .read(habitsProvider.notifier)
          .addActivity(name.text, int.tryParse(minutes.text) ?? 0, note.text);
    }
    name.dispose();
    minutes.dispose();
    note.dispose();
  }

  Future<void> _note(BuildContext context, WidgetRef ref) async {
    final text = TextEditingController();
    final result = await _dialog(context, 'Anotação do dia', [
      TextField(
        controller: text,
        maxLines: 4,
        maxLength: 2000,
        decoration: const InputDecoration(labelText: 'Texto privado'),
      ),
    ]);
    if (result) {
      ref.read(habitsProvider.notifier).addNote(text.text);
    }
    text.dispose();
  }

  Future<bool> _dialog(
    BuildContext context,
    String title,
    List<Widget> fields,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(title),
          content: Column(mainAxisSize: MainAxisSize.min, children: fields),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ) ??
      false;
}
