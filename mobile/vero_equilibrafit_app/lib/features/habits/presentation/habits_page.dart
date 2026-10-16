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
class HabitsState {
  const HabitsState({this.waterMl = 0, this.mobilityDone = false});
  final int waterMl;
  final bool mobilityDone;
  HabitsState copyWith({int? waterMl, bool? mobilityDone}) => HabitsState(
    waterMl: waterMl ?? this.waterMl,
    mobilityDone: mobilityDone ?? this.mobilityDone,
  );
}

class HabitsNotifier extends StateNotifier<HabitsState> {
  HabitsNotifier(this._store, {required String ownerId})
    : _storageKey = ownerScopedKey(ownerId, 'habits_v3_secure'),
      super(const HabitsState()) {
    _restore();
  }
  final SecureOwnerStore _store;
  final String _storageKey;

  Future<void> _restore() async {
    final encoded = await _store.read(_storageKey);
    if (encoded == null || encoded.isEmpty) return;
    try {
      final saved = jsonDecode(encoded) as Map<String, dynamic>;
      if (mounted) {
        state = HabitsState(
          waterMl: saved['waterMl'] as int? ?? 0,
          mobilityDone: saved['mobilityDone'] as bool? ?? false,
        );
      }
    } on FormatException {
      // Ignore only corrupt local cache; never infer an owner for old data.
    }
  }

  void addWater() {
    state = state.copyWith(waterMl: state.waterMl + 250);
    unawaited(_save());
  }

  void setMobility(bool done) {
    state = state.copyWith(mobilityDone: done);
    unawaited(_save());
  }

  Future<void> _save() => _store.write(
    _storageKey,
    jsonEncode({'waterMl': state.waterMl, 'mobilityDone': state.mobilityDone}),
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
    final habits = ref.watch(habitsProvider);
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
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.water_drop_outlined),
              title: const Text('Hidratação'),
              subtitle: Text('${habits.waterMl} ml registrados hoje'),
              trailing: FilledButton(
                onPressed: () => ref.read(habitsProvider.notifier).addWater(),
                child: const Text('+ 250 ml'),
              ),
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.self_improvement_outlined),
              title: const Text('Mobilidade'),
              subtitle: const Text('Marque quando concluir sua prática.'),
              value: habits.mobilityDone,
              onChanged: ref.read(habitsProvider.notifier).setMobility,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Registros locais são preservados neste aparelho. A sincronização segura será disponibilizada depois da configuração da conta.',
            ),
          ),
        ],
      ),
    );
  }
}
