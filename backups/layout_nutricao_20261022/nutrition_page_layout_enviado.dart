import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/app_drawer.dart';
import '../../../shared/presentation/vero_design.dart';
import '../data/meal_photo_analysis_repository.dart';
import 'nutrition_providers.dart';
import 'nutrition_goals_page.dart';
import '../domain/meal_entry.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Nutrição', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt_outlined, color: AppColors.textDark), onPressed: () {}),
          IconButton(icon: const Icon(Icons.qr_code_scanner, color: AppColors.textDark), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () {},
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Registrar Refeição', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Seletor de Data
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {}),
              const Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Hoje, 24 de Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 16),

          // Balanço Energético
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('BALANÇO ENERGÉTICO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        SizedBox(height: 4),
                        Text('1.450 / 2.100 kcal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(16)),
                      child: const Text('🔥 650 restantes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    )
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0.69,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMacroPill('Proteínas', '85g / 140g', const Color(0xFF00A86B)),
                    const SizedBox(width: 8),
                    _buildMacroPill('Carbos', '160g / 220g', const Color(0xFF8B5CF6)),
                    const SizedBox(width: 8),
                    _buildMacroPill('Gorduras', '42g / 65g', const Color(0xFF64748B)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Refeições do dia
          const Text('Diário Alimentar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
          const SizedBox(height: 12),
          _buildMealCard('Café da Manhã', '08:15 • 2 itens', '320 kcal', 'Ovos mexidos (2 unid) + Café com leite'),
          const SizedBox(height: 12),
          _buildMealCard('Almoço', '12:40 • 3 itens', '610 kcal', 'Frango grelhado, arroz integral e legumes'),
          const SizedBox(height: 12),
          _buildEmptyMealCard('Lanche da Tarde', '~280 kcal recomendadas'),
          const SizedBox(height: 12),
          _buildEmptyMealCard('Jantar', '~550 kcal meta'),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMacroPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(radius: 3, backgroundColor: color),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(String meal, String time, String kcal, String summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(meal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(kcal, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text(summary, style: const TextStyle(fontSize: 12.5, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _buildEmptyMealCard(String meal, String recommendation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(recommendation, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primaryLight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('+ Adicionar', style: TextStyle(fontSize: 12)),
          )
        ],
      ),
    );
  }
}