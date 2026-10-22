import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vero_equilibrafit_app/core/persistence/preferences_provider.dart';
import 'package:vero_equilibrafit_app/core/persistence/secure_owner_store.dart';
import 'package:vero_equilibrafit_app/features/auth/presentation/current_owner_provider.dart';
import 'package:vero_equilibrafit_app/features/nutrition/presentation/nutrition_page.dart';
import 'package:vero_equilibrafit_app/features/nutrition/presentation/nutrition_providers.dart';

void main() {
  Widget app(Widget page) => ProviderScope(
    overrides: [
      currentOwnerIdProvider.overrideWithValue('test-owner'),
      secureOwnerStoreProvider.overrideWithValue(MemorySecureOwnerStore()),
      nutritionDiaryDateProvider.overrideWith((ref) => DateTime(2025, 5, 12)),
    ],
    child: MaterialApp(home: page),
  );

  testWidgets('novo registro usa o dia selecionado e rejeita valor negativo', (
    tester,
  ) async {
    await tester.pumpWidget(app(const NutritionMealFormPage()));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(NutritionMealFormPage));
    final displayedDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(DateTime(2025, 5, 12));
    expect(find.textContaining(displayedDate), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'O que você comeu?'),
      'Almoço',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Calorias (kcal)'),
      '-10',
    );
    await tester.scrollUntilVisible(
      find.text('Salvar refeição'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Salvar refeição'));
    await tester.pumpAndSettle();
    expect(find.textContaining('não negativos'), findsOneWidget);
    expect(ProviderScope.containerOf(context).read(mealsProvider), isEmpty);
  });

  testWidgets('edição de registro indisponível não abre formulário novo', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const NutritionMealFormPage(mealId: 'inexistente')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('indisponível ou carregando'), findsOneWidget);
    expect(find.text('Salvar refeição'), findsNothing);
  });
}
