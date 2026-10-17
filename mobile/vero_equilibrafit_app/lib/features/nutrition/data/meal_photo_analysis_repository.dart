import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/data/auth_repository.dart';

class MealPhotoAnalysis {
  const MealPhotoAnalysis({required this.items, required this.message});
  final List<MealPhotoItem> items;
  final String message;
}

class MealPhotoItem {
  const MealPhotoItem({
    required this.name,
    required this.portion,
    required this.unit,
    required this.calories,
    required this.proteinGrams,
    required this.carbohydrateGrams,
    required this.fatGrams,
  });
  final String name;
  final num portion;
  final String unit;
  final num calories;
  final num proteinGrams;
  final num carbohydrateGrams;
  final num fatGrams;
}

class MealPhotoAnalysisRepository {
  MealPhotoAnalysisRepository(this._session, {http.Client? client})
    : _client = client ?? http.Client();
  final AuthSession _session;
  final http.Client _client;

  Future<MealPhotoAnalysis> analyze({
    required List<int> bytes,
    required String mimeType,
    String? context,
  }) async {
    if (AuthRepository.apiBaseUrl.isEmpty) {
      throw const MealPhotoAnalysisException(
        'Defina API_BASE_URL para analisar uma foto.',
      );
    }
    final response = await _client.post(
      Uri.parse('${AuthRepository.apiBaseUrl}/api/v1/meals/analyze-photo'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_session.accessToken}',
      },
      body: jsonEncode({
        'imageBase64': base64Encode(bytes),
        'mimeType': mimeType,
        'mealContext': context,
      }),
    );
    if (response.statusCode != 200) {
      throw MealPhotoAnalysisException(
        'Não foi possível analisar a foto. Revise ou registre manualmente.',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const [])
        .map((item) => item as Map<String, dynamic>)
        .map(
          (item) => MealPhotoItem(
            name: item['name'] as String? ?? 'Alimento',
            portion: item['portion'] as num? ?? 0,
            unit: item['unit'] as String? ?? 'porção',
            calories: item['calories'] as num? ?? 0,
            proteinGrams: item['proteinGrams'] as num? ?? 0,
            carbohydrateGrams: item['carbohydrateGrams'] as num? ?? 0,
            fatGrams: item['fatGrams'] as num? ?? 0,
          ),
        )
        .toList(growable: false);
    return MealPhotoAnalysis(
      items: items,
      message: data['message'] as String? ?? 'Revise antes de salvar.',
    );
  }

  Future<MealPhotoAnalysis> estimateText({
    required String description,
    required String mealType,
  }) async {
    if (AuthRepository.apiBaseUrl.isEmpty) {
      throw const MealPhotoAnalysisException(
        'Defina API_BASE_URL para estimar uma refeição.',
      );
    }
    final response = await _client
        .post(
          Uri.parse('${AuthRepository.apiBaseUrl}/api/v1/meals/estimate-text'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_session.accessToken}',
          },
          body: jsonEncode({'description': description, 'mealType': mealType}),
        )
        .timeout(const Duration(seconds: 35));
    if (response.statusCode != 200) {
      throw const MealPhotoAnalysisException(
        'Não foi possível estimar esta refeição agora.',
      );
    }
    return _fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  MealPhotoAnalysis _fromJson(Map<String, dynamic> data) {
    final items = (data['items'] as List<dynamic>? ?? const [])
        .map((item) => item as Map<String, dynamic>)
        .map(
          (item) => MealPhotoItem(
            name: item['name'] as String? ?? 'Alimento',
            portion: item['portion'] as num? ?? 0,
            unit: item['unit'] as String? ?? 'porção',
            calories: item['calories'] as num? ?? 0,
            proteinGrams: item['proteinGrams'] as num? ?? 0,
            carbohydrateGrams: item['carbohydrateGrams'] as num? ?? 0,
            fatGrams: item['fatGrams'] as num? ?? 0,
          ),
        )
        .toList(growable: false);
    return MealPhotoAnalysis(
      items: items,
      message: data['message'] as String? ?? 'Revise antes de salvar.',
    );
  }
}

class MealPhotoAnalysisException implements Exception {
  const MealPhotoAnalysisException(this.message);
  final String message;
}
