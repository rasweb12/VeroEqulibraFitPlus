import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vero_equilibrafit_app/features/auth/data/auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'recusa resposta de renovação de outra conta antes de gravar tokens',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_access_token': 'old-access',
        'auth_refresh_token': 'old-refresh',
        'auth_email': 'a@example.test',
        'auth_user_id': 'user-a',
      });
      const storage = FlutterSecureStorage();
      final repository = AuthRepository(
        storage: storage,
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'accessToken': 'other-access',
              'refreshToken': 'other-refresh',
              'email': 'b@example.test',
              'userId': 'user-b',
            }),
            200,
          ),
        ),
      );

      await expectLater(repository.refresh(), throwsA(isA<AuthException>()));
      expect(await storage.read(key: 'auth_access_token'), 'old-access');
      expect(await storage.read(key: 'auth_refresh_token'), 'old-refresh');
      expect(await storage.read(key: 'auth_user_id'), 'user-a');
    },
    skip: AuthRepository.apiBaseUrl.isEmpty
        ? 'Exige API_BASE_URL de teste'
        : false,
  );
}
