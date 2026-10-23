import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../appcolors.dart';
import '../../../shared/presentation/app_drawer.dart';
import '../../../shared/presentation/vero_design.dart';
import 'measurements_providers.dart';

class BodyEvolutionScreen extends StatelessWidget {
  const BodyEvolutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textDark), onPressed: () {}),
        title: const Text('Evolução Corporal', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () {},
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Registrar medida', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Card de Resumo de Peso
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ÚLTIMO REGISTRO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                      child: const Text('📉 -2.4 kg este mês', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: const [
                    Text('80.0', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                    SizedBox(width: 4),
                    Text('kg', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('META ALVO', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                        Text('76.0 kg', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.border),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Início: 82.4 kg', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text('Atual: 80.0 kg', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    Text('-2.9%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Histórico de Medições', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
          const SizedBox(height: 12),

          _buildHistoryCard('80.0 kg', '24 de Outubro de 2026', '89.0 cm', '120.0 cm', '89.0 cm', isLatest: true),
          const SizedBox(height: 12),
          _buildHistoryCard('80.6 kg', '17 de Outubro de 2026', '89.8 cm', '120.2 cm', '89.5 cm'),
          const SizedBox(height: 12),
          _buildHistoryCard('81.2 kg', '10 de Outubro de 2026', '90.5 cm', '120.5 cm', '90.0 cm'),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(String weight, String date, String waist, String chest, String hip, {bool isLatest = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(weight, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (isLatest) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                      child: const Text('MAIS RECENTE', style: TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    )
                  ]
                ],
              ),
              IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted), onPressed: () {}),
            ],
          ),
          Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMeasureItem('Cintura', waist),
              _buildMeasureItem('Peito', chest),
              _buildMeasureItem('Quadril', hip),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasureItem(String part, String val) {
    return Column(
      children: [
        Text(part, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
      ],
    );
  }
}