import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/app_drawer.dart';
import '../../../shared/presentation/vero_design.dart';
import '../data/coach_repository.dart';
import 'coach_providers.dart';

class CoachPage extends ConsumerStatefulWidget {
  const CoachPage({super.key});

  @override
  ConsumerState<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends ConsumerState<CoachPage> {
  final _message = TextEditingController();
  final List<_CoachTurn> _turns = [];
  String? _error;
  var _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: const AppDrawer(),
    bottomNavigationBar: const VeroBottomNavigation(location: '/coach'),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Builder(
          builder: (context) => VeroTopBar(
            title: 'Coach Gemini',
            onMenu: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VeroColors.gemini.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_rounded, color: VeroColors.gemini),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Orientação como apoio',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'O Coach usa somente Gemini pela API autenticada. Ele não substitui profissionais de saúde e nunca altera uma ficha sem sua confirmação.',
        ),
        const SizedBox(height: 20),
        const Text(
          'SUGESTÕES RÁPIDAS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: VeroColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                    'Sugestão pós-treino',
                    'Ajustar hidratação',
                    'Dúvida sobre execução',
                  ]
                  .map(
                    (suggestion) => ActionChip(
                      label: Text(suggestion),
                      onPressed: _sending
                          ? null
                          : () => setState(() => _message.text = suggestion),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _message,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            labelText: 'Sua pergunta',
            hintText: 'Ex.: Como posso adaptar meu treino hoje?',
          ),
          onChanged: (_) => setState(() {}),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_message.text.length}/1000',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _sending ? null : _send,
          icon: _sending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: const Text('Perguntar ao Coach'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!),
            ),
          ),
        ],
        if (_turns.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Nesta sessão', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final turn in _turns) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8, left: 40),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(turn.question),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: VeroColors.gemini,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Resposta do Coach',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(turn.reply.content),
                    const SizedBox(height: 12),
                    Text(
                      'Modelo: ${turn.reply.model}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'As mensagens não são gravadas como histórico permanente nesta tela.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => context.go('/nutrition'),
          icon: const Icon(Icons.restaurant_outlined),
          label: const Text('Registrar uma refeição'),
        ),
      ],
    ),
  );

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.length < 3 || text.length > 1000) {
      setState(
        () => _error = 'Escreva uma pergunta entre 3 e 1000 caracteres.',
      );
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final reply = await ref.read(coachRepositoryProvider).sendMessage(text);
      if (!mounted) return;
      setState(() {
        _turns.add(_CoachTurn(question: text, reply: reply));
        _message.clear();
      });
    } on CoachUnavailable catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível consultar o Coach agora.');
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}

class _CoachTurn {
  const _CoachTurn({required this.question, required this.reply});

  final String question;
  final CoachReply reply;
}
