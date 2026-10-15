import 'package:flutter/material.dart';

class AuthSplashPage extends StatelessWidget {
  const AuthSplashPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Verificando sua sessão com segurança...'),
        ],
      ),
    ),
  );
}
