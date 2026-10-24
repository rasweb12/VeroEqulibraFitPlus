import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    backgroundColor: VeroColors.background,
    drawer: const AppDrawer(),
    appBar: AppBar(
      backgroundColor: VeroColors.surface,
      surfaceTintColor: VeroColors.surface,
      elevation: 0,
      leading: Builder(
        builder: (scaffoldContext) => IconButton(
          tooltip: 'Menu',
          onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
          icon: const Icon(Icons.menu_rounded, color: VeroColors.text),
        ),
      ),
      title: const Text(
        'Coach Gemini',
        style: TextStyle(fontWeight: FontWeight.w800, color: VeroColors.text),
      ),
      centerTitle: true,
    ),
    bottomNavigationBar: const VeroBottomNavigation(location: '/coach'),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            children: [
              _supportNotice(),
              const SizedBox(height: 16),
              _insightCard(context),
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
                          'Ajustar meta de água',
                          'Dúvida sobre execução',
                        ]
                        .map(
                          (suggestion) => ActionChip(
                            avatar: Icon(
                              _suggestionIcon(suggestion),
                              size: 16,
                              color: VeroColors.gemini,
                            ),
                            label: Text(suggestion),
                            labelStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: VeroColors.surface,
                            side: const BorderSide(color: VeroColors.border),
                            onPressed: _sending
                                ? null
                                : () => setState(
                                    () => _message.text = suggestion,
                                  ),
                          ),
                        )
                        .toList(),
              ),
              if (_error != null) ...[const SizedBox(height: 16), _errorCard()],
              const SizedBox(height: 20),
              if (_turns.isEmpty) _emptyConversationCard() else _conversation(),
            ],
          ),
        ),
        _composer(context),
      ],
    ),
  );

  Widget _supportNotice() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: VeroColors.waterLight,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.verified_user_outlined, color: VeroColors.water, size: 20),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'O Coach usa a API autenticada Gemini como apoio informativo. Não substitui profissionais de saúde ou de treino.',
            style: TextStyle(fontSize: 11.5, color: Color(0xff1E40AF)),
          ),
        ),
      ],
    ),
  );

  Widget _insightCard(BuildContext context) {
    final latest = _turns.isEmpty ? null : _turns.last;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VeroColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VeroColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: VeroColors.gemini,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Insight pessoal',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            latest == null
                ? 'Pergunte sobre seus registros de treino e nutrição. O Coach responde quando os dados necessários estiverem disponíveis.'
                : latest.reply.content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: VeroColors.text,
            ),
          ),
          if (latest != null) ...[
            const SizedBox(height: 12),
            Text(
              'Resposta gerada por ${latest.reply.model}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: VeroColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyConversationCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: VeroColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: VeroColors.border),
    ),
    child: const Row(
      children: [
        Icon(Icons.chat_bubble_outline_rounded, color: VeroColors.gemini),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Envie uma pergunta para iniciar a conversa. As mensagens desta tela ficam disponíveis durante esta sessão.',
            style: TextStyle(fontSize: 12.5, color: VeroColors.muted),
          ),
        ),
      ],
    ),
  );

  Widget _conversation() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'CONVERSA DESTA SESSÃO',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: VeroColors.muted,
        ),
      ),
      const SizedBox(height: 10),
      for (final turn in _turns) ...[
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8, left: 40),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: VeroColors.primaryLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(turn.question),
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(right: 18, bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: VeroColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VeroColors.border),
          ),
          child: Text(turn.reply.content, style: const TextStyle(height: 1.45)),
        ),
      ],
    ],
  );

  Widget _errorCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xffFEF2F2),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xffFECACA)),
    ),
    child: Text(_error!, style: const TextStyle(color: Color(0xff991B1B))),
  );

  Widget _composer(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    decoration: const BoxDecoration(
      color: VeroColors.surface,
      border: Border(top: BorderSide(color: VeroColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _message,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Sua dúvida sobre treino ou nutrição...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: VeroColors.muted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: VeroColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: VeroColors.primary,
                child: IconButton(
                  tooltip: 'Enviar pergunta',
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_message.text.length}/1000',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    ),
  );

  IconData _suggestionIcon(String value) => switch (value) {
    'Sugestão pós-treino' => Icons.restaurant_outlined,
    'Ajustar meta de água' => Icons.water_drop_outlined,
    _ => Icons.fitness_center_outlined,
  };

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
