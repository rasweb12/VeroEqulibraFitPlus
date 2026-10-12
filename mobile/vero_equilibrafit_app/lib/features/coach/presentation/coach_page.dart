import 'package:flutter/material.dart';

import '../../../shared/presentation/app_drawer.dart';
import '../data/coach_repository.dart';

class CoachPage extends StatefulWidget {
  const CoachPage({super.key});

  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends State<CoachPage> {
  final _message = TextEditingController();
  final _repository = CoachRepository();
  CoachReply? _reply;
  String? _error;
  var _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Coach Gemini')),
    drawer: const AppDrawer(),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Orientação como apoio',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'O Coach usa somente Gemini pela API autenticada. Ele não substitui profissionais de saúde e nunca altera uma ficha sem sua confirmação.',
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _message,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Sua pergunta',
            hintText: 'Ex.: Como posso adaptar meu treino hoje?',
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
        if (_reply != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resposta do Coach',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(_reply!.content),
                  const SizedBox(height: 12),
                  Text(
                    'Modelo: ${_reply!.model}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.length < 3) {
      setState(
        () => _error = 'Escreva uma pergunta com pelo menos três caracteres.',
      );
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final reply = await _repository.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _reply = reply;
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
