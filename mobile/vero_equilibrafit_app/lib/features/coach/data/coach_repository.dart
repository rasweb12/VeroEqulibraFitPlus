import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/data/auth_repository.dart';

class CoachReply {
  const CoachReply({
    required this.content,
    required this.model,
    required this.fallbackUsed,
  });
  final String content;
  final String model;
  final bool fallbackUsed;
}

class CoachRepository {
  factory CoachRepository({
    http.Client? client,
    String? baseUrl,
    String? accessToken,
  }) => CoachRepository._(
    client ?? http.Client(),
    baseUrl ?? AuthRepository.apiBaseUrl,
    accessToken,
  );

  CoachRepository._(this._client, this._baseUrl, this._accessToken);

  final http.Client _client;
  final String _baseUrl;
  final String? _accessToken;

  Future<CoachReply> sendMessage(String message) async {
    if (_baseUrl.isEmpty) {
      throw const CoachUnavailable(
        'Configure o endereço da API para usar o Coach Gemini.',
      );
    }
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/v1/ai/coach/messages'),
          headers: {
            'Content-Type': 'application/json',
            if (_accessToken?.isNotEmpty ?? false)
              'Authorization': 'Bearer $_accessToken',
          },
          body: jsonEncode({'message': message}),
        )
        .timeout(const Duration(seconds: 35));
    if (response.statusCode == 401) {
      throw const CoachUnavailable(
        'Entre na sua conta para usar o Coach Gemini.',
      );
    }
    if (response.statusCode != 200) {
      throw const CoachUnavailable(
        'O Coach não está disponível agora. Você pode continuar registrando seu treino manualmente.',
      );
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return CoachReply(
      content: payload['content'] as String? ?? '',
      model: payload['model'] as String? ?? 'gemini',
      fallbackUsed: payload['fallbackUsed'] as bool? ?? false,
    );
  }
}

class CoachUnavailable implements Exception {
  const CoachUnavailable(this.message);
  final String message;
}
