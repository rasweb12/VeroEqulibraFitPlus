import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  HabitsNotifier() : super(const HabitsState());
  void addWater() => state = state.copyWith(waterMl: state.waterMl + 250);
  void setMobility(bool done) => state = state.copyWith(mobilityDone: done);
}

final habitsProvider = StateNotifierProvider<HabitsNotifier, HabitsState>(
  (ref) => HabitsNotifier(),
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
              'A persistência offline e a sincronização desta tela serão conectadas à fila Isar na próxima integração da API.',
            ),
          ),
        ],
      ),
    );
  }
}
