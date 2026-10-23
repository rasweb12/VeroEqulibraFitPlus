import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vero_equilibrafit_app/core/persistence/preferences_provider.dart';
import 'package:vero_equilibrafit_app/core/persistence/secure_owner_store.dart';
import 'package:vero_equilibrafit_app/features/auth/presentation/current_owner_provider.dart';
import 'package:vero_equilibrafit_app/features/nutrition/presentation/nutrition_page.dart';

void main() {
  testWidgets('diário abre formulário da categoria sem dados de exemplo', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/nutrition',
      routes: [
        GoRoute(path: '/nutrition', builder: (_, _) => const NutritionPage()),
        GoRoute(
          path: '/nutrition/new',
          builder: (_, state) => Scaffold(
            body: Text('categoria: ${state.uri.queryParameters['mealType']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentOwnerIdProvider.overrideWithValue('test-owner'),
          secureOwnerStoreProvider.overrideWithValue(MemorySecureOwnerStore()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Café da manhã'), findsOneWidget);
    expect(find.text('Ovos mexidos (2 unid) + Café com leite'), findsNothing);
    await tester.tap(find.byTooltip('Adicionar em Café da manhã'));
    await tester.pumpAndSettle();
    expect(find.text('categoria: Café da manhã'), findsOneWidget);
  });
}
