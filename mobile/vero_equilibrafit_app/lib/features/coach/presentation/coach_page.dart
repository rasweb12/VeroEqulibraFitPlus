import 'package:flutter/material.dart';
import '../../../shared/presentation/app_drawer.dart';

class CoachPage extends StatelessWidget {
  const CoachPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Coach Gemini')),
    drawer: const AppDrawer(),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orientação como apoio',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'O Coach usa somente Gemini através da API autenticada. Sugestões não substituem acompanhamento profissional e não alteram seu plano sem confirmação.',
          ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Configure VERO_EQUILIBRAFIT_INTERNAL_API_KEY e GEMINI_API_KEY no serviço privado para habilitar solicitações reais.',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
