import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_services.dart';
import '../models/user_model.dart';
import 'auth/login_screen.dart';
import 'admin/admin_home_screen.dart'; // <--- Importando a tela REAL do Admin

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // 1º Passo: Checa se há uma sessão ativa no Firebase Auth
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.green)),
          );
        }

        // Se o usuário ESTÁ logado
        if (snapshot.hasData) {
          // 2º Passo: Busca os dados completos (UserModel) dele no Firestore
          return FutureBuilder<UserModel?>(
            future: UserServices().getUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                );
              }

              // Se os dados do usuário logado foram encontrados no banco
              if (userSnapshot.hasData && userSnapshot.data != null) {
                return AdminHomeScreen(user: userSnapshot.data!);
              }

              // Fallback de segurança: se logou mas o documento no Firestore não existe, volta pro login
              AuthService().logout();
              return const LoginScreen();
            },
          );
        }

        // Se o usuário NÃO ESTÁ logado
        return const LoginScreen();
      },
    );
  }
}
