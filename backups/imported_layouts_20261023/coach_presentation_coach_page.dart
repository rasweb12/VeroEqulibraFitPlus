import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../appcolors.dart';
import '../../../shared/presentation/app_drawer.dart';
import '../../../shared/presentation/vero_design.dart';
import '../data/coach_repository.dart';
import 'coach_providers.dart';

class CoachGeminiScreen extends StatelessWidget {
  const CoachGeminiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textDark), onPressed: () {}),
        title: const Text('Coach Gemini', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Orientação de Segurança / Disclaimer
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: Color(0xFF2563EB), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'O Coach usa a API autenticada Gemini para suporte preventivo. Não substitui médicos ou treinadores.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF)),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Balão do Insight do Coach
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.smart_toy_outlined, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('Insight Pessoal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Spacer(),
                          Text('Hoje • 08:42', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Olá, Ronaldo! Analisei seu treino de hipertrofia de hoje (FC média 142 bpm) e seu gasto de 580 kcal. Como posso calibrar sua recuperação muscular e hidratação hoje?',
                        style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildTelemetryChip('Cardio', '48 min'),
                          const SizedBox(width: 8),
                          _buildTelemetryChip('Carga', '3.450 kg'),
                          const SizedBox(width: 8),
                          _buildTelemetryChip('Sono', '8h 12m'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('SUGESTÕES RÁPIDAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(label: const Text('🍴 Sugestão pós-treino'), onPressed: () {}),
                    ActionChip(label: const Text('💧 Ajustar meta de água'), onPressed: () {}),
                    ActionChip(label: const Text('🏋️ Dúvida sobre execução'), onPressed: () {}),
                  ],
                ),
              ],
            ),
          ),

          // Campo de Entrada
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.camera_alt_outlined, color: AppColors.textMuted), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.mic_none, color: AppColors.textMuted), onPressed: () {}),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Sua dúvida sobre treino ou nutrição...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: () {}),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryChip(String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF1E40AF))),
            Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          ],
        ),
      ),
    );
  }
}