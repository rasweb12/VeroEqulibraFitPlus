import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../../shared/presentation/vero_design.dart';
import 'nutrition_back_button.dart';

class NutritionPlansPage extends ConsumerStatefulWidget {
  const NutritionPlansPage({super.key});
  @override
  ConsumerState<NutritionPlansPage> createState() => _NutritionPlansPageState();
}

class _NutritionPlansPageState extends ConsumerState<NutritionPlansPage> {
  final objective = TextEditingController(),
      preferences = TextEditingController(),
      restrictions = TextEditingController(),
      planName = TextEditingController(text: 'Plano alimentar'),
      proposalEditor = TextEditingController();
  String? proposal;
  String? editingPlanId;
  List<Map<String, dynamic>> savedPlans = const [];
  bool loading = false;
  String? error;
  @override
  void dispose() {
    objective.dispose();
    preferences.dispose();
    restrictions.dispose();
    planName.dispose();
    proposalEditor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const NutritionBackButton(),
      title: const Text('Plano alimentar'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VeroColors.gemini.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_outlined, color: VeroColors.gemini),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Crie uma proposta flexível e revise cada sugestão antes de salvar.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: objective,
          decoration: const InputDecoration(labelText: 'Objetivo'),
        ),
        TextField(
          controller: preferences,
          decoration: const InputDecoration(
            labelText: 'Preferências (separadas por vírgula)',
          ),
        ),
        TextField(
          controller: restrictions,
          decoration: const InputDecoration(
            labelText: 'Alergias e restrições (separadas por vírgula)',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: loading ? null : generate,
          child: Text(loading ? 'Gerando...' : 'Gerar proposta com Gemini'),
        ),
        TextButton.icon(
          onPressed: loading ? null : loadSavedPlans,
          icon: const Icon(Icons.folder_open_outlined),
          label: const Text('Carregar plano salvo'),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (proposal != null) ...[
          const SizedBox(height: 20),
          Text(
            'Revise a proposta antes de aprovar.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(_summary(proposal!)),
          const SizedBox(height: 12),
          TextField(
            controller: planName,
            decoration: const InputDecoration(labelText: 'Nome do plano'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: proposalEditor,
            minLines: 5,
            maxLines: 16,
            decoration: const InputDecoration(
              labelText: 'Conteúdo do plano (JSON revisável)',
              helperText:
                  'Revise refeições, alternativas e observações antes de salvar.',
            ),
            onChanged: (value) => proposal = value,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: approve,
            child: Text(
              editingPlanId == null
                  ? 'Aprovar e salvar plano'
                  : 'Salvar alterações',
            ),
          ),
        ],
      ],
    ),
  );
  Future<void> generate() async {
    if (objective.text.trim().isEmpty) {
      setState(() => error = 'Informe seu objetivo.');
      return;
    }
    await request(
      '/api/v1/nutrition-plans/generate',
      {
        'objective': objective.text.trim(),
        'preferences': _list(preferences.text),
        'restrictions': _list(restrictions.text),
      },
      false,
      'POST',
    );
  }

  Future<void> approve() async {
    final content = proposalEditor.text.trim();
    if (planName.text.trim().isEmpty || content.isEmpty) {
      setState(() => error = 'Informe o nome e o conteúdo do plano.');
      return;
    }
    try {
      jsonDecode(content);
    } catch (_) {
      setState(
        () => error =
            'O conteúdo revisado do plano está inválido. Gere novamente ou ajuste o JSON.',
      );
      return;
    }
    final id = editingPlanId;
    await request(
      id == null ? '/api/v1/nutrition-plans' : '/api/v1/nutrition-plans/$id',
      {'name': planName.text.trim(), 'contentJson': content},
      true,
      id == null ? 'POST' : 'PUT',
    );
    if (mounted && error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Plano aprovado e salvo.')));
    }
  }

  Future<void> request(
    String path,
    Map<String, dynamic> body,
    bool saving,
    String method,
  ) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || AuthRepository.apiBaseUrl.isEmpty) {
      setState(() => error = 'Sessão ou API indisponível.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    final client = http.Client();
    try {
      final request =
          http.Request(method, Uri.parse('${AuthRepository.apiBaseUrl}$path'))
            ..headers.addAll({
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${session.accessToken}',
            })
            ..body = jsonEncode(body);
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 45));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(_message(response));
      }
      if (!saving) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const HttpException(
            'A resposta da proposta é inválida. Tente novamente.',
          );
        }
        if (decoded['fallback_used'] == true) {
          throw const HttpException(
            'O Gemini está indisponível. Nenhuma proposta por IA foi gerada; tente novamente mais tarde.',
          );
        }
        if (mounted) {
          setState(() {
            proposal = response.body;
            proposalEditor.text = response.body;
            editingPlanId = null;
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(
          () => error =
              'A solicitação demorou demais. Verifique a conexão e tente novamente.',
        );
      }
    } on http.ClientException {
      if (mounted) {
        setState(
          () => error =
              'Não foi possível conectar ao serviço. Verifique a rede e tente novamente.',
        );
      }
    } on HttpException catch (exception) {
      if (mounted) {
        setState(() => error = exception.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Não foi possível concluir agora. Tente novamente ou revise seus registros manualmente.',
        );
      }
    } finally {
      client.close();
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loadSavedPlans() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || AuthRepository.apiBaseUrl.isEmpty) {
      setState(() => error = 'Sessão ou API indisponível.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await http
          .get(
            Uri.parse('${AuthRepository.apiBaseUrl}/api/v1/nutrition-plans'),
            headers: {'Authorization': 'Bearer ${session.accessToken}'},
          )
          .timeout(const Duration(seconds: 35));
      if (response.statusCode != 200) throw HttpException(_message(response));
      final decoded = jsonDecode(response.body) as List<dynamic>;
      savedPlans = decoded.whereType<Map<String, dynamic>>().toList(
        growable: false,
      );
      if (!mounted) return;
      if (savedPlans.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum plano salvo ainda.')),
        );
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => ListView(
          shrinkWrap: true,
          children: savedPlans
              .map(
                (plan) => ListTile(
                  title: Text(plan['name'] as String? ?? 'Plano alimentar'),
                  subtitle: const Text('Toque para revisar e editar'),
                  onTap: () {
                    final content = plan['contentJson'] as String? ?? '{}';
                    setState(() {
                      editingPlanId = plan['id'] as String?;
                      planName.text =
                          plan['name'] as String? ?? 'Plano alimentar';
                      proposal = content;
                      proposalEditor.text = content;
                    });
                    Navigator.pop(sheetContext);
                  },
                ),
              )
              .toList(growable: false),
        ),
      );
    } on HttpException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Não foi possível carregar seus planos agora.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _message(http.Response response) {
    if (response.statusCode == 401) {
      return 'Sua sessão expirou. Entre novamente para continuar.';
    }
    if (response.statusCode == 403) {
      return 'Sua conta não tem permissão para esta operação.';
    }
    if (response.statusCode == 429) {
      return 'Muitas solicitações. Aguarde e tente novamente.';
    }
    if (response.statusCode >= 500) {
      return 'O serviço de planos está indisponível. Tente novamente mais tarde (${response.statusCode}).';
    }
    try {
      final value = jsonDecode(response.body);
      if (value is Map<String, dynamic> && value['error'] is String) {
        return value['error'] as String;
      }
    } catch (_) {}
    return 'Não foi possível concluir agora (${response.statusCode}).';
  }

  List<String> _list(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  String _summary(String json) {
    try {
      final p = jsonDecode(json) as Map<String, dynamic>;
      return '${p['explanation'] ?? 'Proposta gerada.'}\n\n${(p['meals'] as List? ?? []).map((m) => '• ${m['name']}: ${m['description']}').join('\n')}';
    } catch (_) {
      return 'Proposta pronta para revisão.';
    }
  }
}

class HttpException implements Exception {
  const HttpException(this.message);
  final String message;
}
