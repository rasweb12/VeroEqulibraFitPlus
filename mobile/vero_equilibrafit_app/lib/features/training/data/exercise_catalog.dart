import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/exercise.dart';

/// Reads the versioned, owner-supplied official exercise catalogue.
///
/// The parser is deliberately separate from the asset access so malformed
/// catalogue data can be tested without starting Flutter bindings.
class ExerciseCatalog {
  static const assetPath = 'assets/catalog/exercises.v1.json';

  Future<List<Exercise>> load() async {
    final source = await rootBundle.loadString(assetPath);
    return parse(source);
  }

  static List<Exercise> parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Catálogo oficial inválido.');
    }
    final metadata = decoded['metadata'];
    final exercises = decoded['exercicios'];
    if (metadata is! Map<String, dynamic> || exercises is! List<dynamic>) {
      throw const FormatException('Estrutura do catálogo oficial inválida.');
    }
    if (metadata['versao_schema'] != '1.0.0' ||
        metadata['total_exercicios'] != 200 ||
        exercises.length != 200) {
      throw const FormatException('Versão ou total do catálogo incompatível.');
    }

    final legacyIds = <int>{};
    final ids = <String>{};
    final catalog = <Exercise>[];
    for (final raw in exercises) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Exercício inválido no catálogo oficial.');
      }
      final id = raw['id'];
      final legacyId = raw['legacy_id'];
      final name = raw['nome'];
      final muscle = raw['grupo_muscular'];
      final objective = raw['foco_principal'];
      if (id is! String ||
          legacyId is! int ||
          name is! String ||
          muscle is! String ||
          objective is! String ||
          id.isEmpty ||
          name.isEmpty ||
          muscle.isEmpty ||
          objective.isEmpty ||
          !ids.add(id) ||
          !legacyIds.add(legacyId)) {
        throw const FormatException(
          'Identificadores ou campos obrigatórios inválidos.',
        );
      }
      catalog.add(
        Exercise(
          id: id,
          legacyId: legacyId,
          name: name,
          primaryMuscle: muscle,
          // The supplied list has no authoritative equipment column.
          equipment: raw['equipamento'] as String? ?? 'Não informado',
          aliases: _stringList(raw['aliases']),
          demoVideoAsset: raw['demo_video_asset'] as String?,
          instructions: _stringList(raw['instrucoes']),
          safetyTips: _stringList(raw['dicas_seguranca']),
          objective: objective,
          category: raw['categoria'] as String?,
          schemaVersion: raw['versao_schema'] as String?,
        ),
      );
    }
    if (legacyIds.length != 200 ||
        !legacyIds.containsAll(List<int>.generate(200, (i) => i + 1))) {
      throw const FormatException('IDs legados do catálogo estão incompletos.');
    }
    return List<Exercise>.unmodifiable(catalog);
  }

  static List<String> _stringList(Object? value) {
    if (value == null) return const [];
    if (value is String) return value.isEmpty ? const [] : [value];
    if (value is List<dynamic>) return List<String>.from(value);
    throw const FormatException('Lista textual inválida no catálogo oficial.');
  }
}
