import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vero_equilibrafit_app/core/persistence/preferences_provider.dart';
import 'package:vero_equilibrafit_app/core/persistence/secure_owner_store.dart';
import 'package:vero_equilibrafit_app/features/auth/presentation/current_owner_provider.dart';
import 'package:vero_equilibrafit_app/features/habits/presentation/habits_page.dart';
import 'package:vero_equilibrafit_app/features/measurements/presentation/measurements_page.dart';
import 'package:vero_equilibrafit_app/features/measurements/presentation/measurements_providers.dart';

void main() {
  Widget app(Widget page, MemorySecureOwnerStore store) => ProviderScope(
    overrides: [
      currentOwnerIdProvider.overrideWithValue('test-owner'),
      secureOwnerStoreProvider.overrideWithValue(store),
    ],
    child: MaterialApp(home: page),
  );

  testWidgets('measure dialog cancels and saves repeatedly', (tester) async {
    await tester.pumpWidget(
      app(const MeasurementsPage(), MemorySecureOwnerStore()),
    );
    await tester.pumpAndSettle();

    Future<void> open() async {
      await tester.tap(find.text('Registrar medida'));
      await tester.pumpAndSettle();
    }

    await open();
    await tester.enterText(find.widgetWithText(TextField, 'Peso (kg)'), '70');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('70.0 kg'), findsNothing);
    expect(tester.takeException(), isNull);

    await open();
    await tester.enterText(find.widgetWithText(TextField, 'Peso (kg)'), '72');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.textContaining('72.0 kg'), findsNothing);
    expect(tester.takeException(), isNull);

    for (final weight in ['70', '71']) {
      await open();
      await tester.enterText(
        find.widgetWithText(TextField, 'Peso (kg)'),
        weight,
      );
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('$weight.0 kg'), findsWidgets);
      expect(tester.takeException(), isNull);
    }
    final context = tester.element(find.byType(MeasurementsPage));
    expect(
      ProviderScope.containerOf(context).read(measurementsProvider),
      hasLength(2),
    );
  });

  for (final kind in ['Atividade', 'Anotação do dia']) {
    testWidgets('$kind dialog cancels and saves repeatedly', (tester) async {
      await tester.pumpWidget(
        app(const HabitsPage(), MemorySecureOwnerStore()),
      );
      await tester.pumpAndSettle();

      Future<void> open() async {
        if (kind == 'Anotação do dia') {
          await tester.drag(find.byType(ListView).first, const Offset(0, -250));
          await tester.pumpAndSettle();
        }
        final button = find.text(kind);
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      Future<void> fill() async {
        if (kind == 'Atividade') {
          await tester.enterText(
            find.widgetWithText(TextField, 'Atividade'),
            'Caminhada',
          );
          await tester.enterText(
            find.widgetWithText(TextField, 'Duração em minutos'),
            '20',
          );
        } else {
          await tester.enterText(
            find.widgetWithText(TextField, 'Texto privado'),
            'Teste',
          );
        }
      }

      await open();
      await fill();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(HabitsPage));
      final container = ProviderScope.containerOf(context);
      expect(container.read(habitsProvider).entries, isEmpty);
      expect(tester.takeException(), isNull);

      await open();
      await fill();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(container.read(habitsProvider).entries, isEmpty);
      expect(tester.takeException(), isNull);

      for (var index = 0; index < 2; index++) {
        await open();
        await fill();
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();
        expect(container.read(habitsProvider).entries, hasLength(index + 1));
        expect(tester.takeException(), isNull);
      }
    });
  }
}
