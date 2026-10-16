import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_providers.dart';

class NutritionPlansPage extends ConsumerStatefulWidget { const NutritionPlansPage({super.key}); @override ConsumerState<NutritionPlansPage> createState() => _NutritionPlansPageState(); }
class _NutritionPlansPageState extends ConsumerState<NutritionPlansPage> {
  final objective = TextEditingController(), preferences = TextEditingController(), restrictions = TextEditingController();
  String? proposal; bool loading = false; String? error;
  @override void dispose() { objective.dispose(); preferences.dispose(); restrictions.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Plano alimentar')), body: ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Crie uma proposta flexível e revise cada sugestão antes de salvar.'), const SizedBox(height: 12),
    TextField(controller: objective, decoration: const InputDecoration(labelText: 'Objetivo')), TextField(controller: preferences, decoration: const InputDecoration(labelText: 'Preferências (separadas por vírgula)')), TextField(controller: restrictions, decoration: const InputDecoration(labelText: 'Alergias e restrições (separadas por vírgula)')),
    const SizedBox(height: 16), FilledButton(onPressed: loading ? null : generate, child: Text(loading ? 'Gerando...' : 'Gerar proposta com Gemini')),
    if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    if (proposal != null) ...[const SizedBox(height: 20), Text('Revise a proposta antes de aprovar.', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text(_summary(proposal!)), const SizedBox(height: 12), FilledButton(onPressed: approve, child: const Text('Aprovar e salvar plano'))]
  ]));
  Future<void> generate() async { if (objective.text.trim().isEmpty) { setState(() => error = 'Informe seu objetivo.'); return; } await request('/api/v1/nutrition-plans/generate', {'objective': objective.text.trim(), 'preferences': _list(preferences.text), 'restrictions': _list(restrictions.text)}, false); }
  Future<void> approve() async { await request('/api/v1/nutrition-plans', {'name': 'Plano alimentar', 'contentJson': proposal}, true); if (mounted && error == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plano aprovado e salvo.'))); }
  Future<void> request(String path, Map<String, dynamic> body, bool saving) async { final session = ref.read(authSessionProvider).valueOrNull; if (session == null || AuthRepository.apiBaseUrl.isEmpty) { setState(() => error = 'Sessão ou API indisponível.'); return; } setState(() { loading = true; error = null; }); try { final response = await http.post(Uri.parse('${AuthRepository.apiBaseUrl}$path'), headers: {'Content-Type':'application/json','Authorization':'Bearer ${session.accessToken}'}, body: jsonEncode(body)).timeout(const Duration(seconds: 35)); if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(); if (!saving) setState(() => proposal = response.body); } catch (_) { if (mounted) setState(() => error = 'Não foi possível concluir agora. Você pode revisar seus registros manualmente.'); } finally { if (mounted) setState(() => loading = false); } }
  List<String> _list(String value) => value.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  String _summary(String json) { try { final p = jsonDecode(json) as Map<String,dynamic>; return '${p['explanation'] ?? 'Proposta gerada.'}\n\n${(p['meals'] as List? ?? []).map((m) => '• ${m['name']}: ${m['description']}').join('\n')}'; } catch (_) { return 'Proposta pronta para revisão.'; } }
}
