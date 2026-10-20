import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mantém o retorno funcional mesmo quando a página é aberta diretamente.
class NutritionBackButton extends StatelessWidget {
  const NutritionBackButton({super.key});

  @override
  Widget build(BuildContext context) => BackButton(
    onPressed: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/nutrition');
      }
    },
  );
}
