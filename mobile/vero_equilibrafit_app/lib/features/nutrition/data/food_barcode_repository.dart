import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/auth_repository.dart';

class FoodBarcodeProduct {
  const FoodBarcodeProduct({
    required this.name,
    required this.gtin,
    this.brand,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    required this.source,
  });
  final String name, gtin, source;
  final String? brand;
  final double? calories, protein, carbs, fat, fiber;
  factory FoodBarcodeProduct.fromJson(Map<String, dynamic> json) =>
      FoodBarcodeProduct(
        name: json['name'] as String,
        gtin: json['gtin'] as String,
        brand: json['brand'] as String?,
        calories: (json['calories'] as num?)?.toDouble(),
        protein: (json['proteinGrams'] as num?)?.toDouble(),
        carbs: (json['carbohydrateGrams'] as num?)?.toDouble(),
        fat: (json['fatGrams'] as num?)?.toDouble(),
        fiber: (json['fiberGrams'] as num?)?.toDouble(),
        source: json['source'] as String,
      );
}

class FoodBarcodeRepository {
  FoodBarcodeRepository({http.Client? client, AuthRepository? auth})
    : _client = client ?? http.Client(),
      _auth = auth ?? AuthRepository();
  final http.Client _client;
  final AuthRepository _auth;
  Future<FoodBarcodeProduct?> lookup(String gtin) async {
    final session = await _auth.restore();
    if (session == null || AuthRepository.apiBaseUrl.isEmpty) {
      throw const FoodBarcodeException(
        'Entre em uma conta conectada para consultar o catálogo.',
      );
    }
    final response = await _client.get(
      Uri.parse('${AuthRepository.apiBaseUrl}/api/v1/foods/barcode/$gtin'),
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw const FoodBarcodeException(
        'Não foi possível consultar o catálogo agora.',
      );
    }
    return FoodBarcodeProduct.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

class FoodBarcodeException implements Exception {
  const FoodBarcodeException(this.message);
  final String message;
}
