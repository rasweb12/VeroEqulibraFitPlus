import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../appcolors.dart';
import '../../../core/persistence/owner_scope.dart';
import '../../../core/persistence/preferences_provider.dart';
import '../../../core/persistence/secure_owner_store.dart';
import '../../auth/presentation/current_owner_provider.dart';
import '../../../shared/presentation/app_drawer.dart';
import '../../../shared/presentation/vero_design.dart';
import 'package:go_router/go_router.dart';

class HabitsHydrationScreen extends StatefulWidget {
  const HabitsHydrationScreen({super.key});

  @override
  State<HabitsHydrationScreen> createState() => _HabitsHydrationScreenState();
}

class _HabitsHydrationScreenState extends State<HabitsHydrationScreen> {
  int currentWaterMl = 1250;
  final int targetWaterMl = 2000;
  bool isMobilityDone = true;

  @override
  Widget build(BuildContext context) {
    final double waterRatio = (currentWaterMl / targetWaterMl).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Início', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Registre o que fez hoje', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const Text('No seu ritmo, construindo consistência dia após dia.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 20),

          // Card Hidratação
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.blueWaterLight, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.water_drop, color: AppColors.blueWater, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hidratação', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('$currentWaterMl de $targetWaterMl ml hoje', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                    Text('${(waterRatio * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.blueWater)),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: waterRatio,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('ADIÇÃO RÁPIDA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [150, 200, 250, 300, 500].map((amount) {
                    return ActionChip(
                      label: Text('+ $amount ml'),
                      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                      backgroundColor: const Color(0xFFE0F2FE),
                      side: BorderSide.none,
                      onPressed: () {
                        setState(() {
                          currentWaterMl = (currentWaterMl + amount).clamp(0, targetWaterMl + 1000);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card Mobilidade
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                const Icon(Icons.self_improvement, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mobilidade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Prática matinal de 12 min registrada.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Switch(
                  value: isMobilityDone,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => isMobilityDone = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card Anotação do Dia
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.edit_note, color: Colors.purple, size: 24),
                        SizedBox(width: 8),
                        Text('Anotação do dia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.primary), onPressed: () {}),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: const Text('"Boa energia hoje pela manhã. Ombros soltos após a mobilidade."', style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: AppColors.textDark)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}