import 'package:flutter/material.dart';
import '../services/user_services.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      // 1. A pergunta que estamos fazendo ao banco
      future: UserServices().getUserData(),

      builder: (context, snapshot) {
        // 2. Enquanto o banco não responde (Carregando...)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Erro ao carregar perfil. Tente logar novamente."),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => AuthService().logout(),
                    child: const Text('Sair'),
                  ),
                ],
              ),
            ),
          );
        }

        final UserModel user = snapshot.data!;

        if (user.isAdmin) {
          return _buildAdminScreen(user);
        } else {
          return _buildClientScreen(user);
        }
      },
    );
  }

  Widget _buildAdminScreen(UserModel user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel do Dono"),
        backgroundColor: Colors.blueGrey, // Cor mais séria para admin
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 16),
            Text("Olá, ${user.nome}!", style: const TextStyle(fontSize: 24)),
            const Text("Aqui você vai gerenciar os campos."),
          ],
        ),
      ),
    );
  }

  // --- TELA PROVISÓRIA DO CLIENTE ---
  Widget _buildClientScreen(UserModel user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agendar Jogo"),
        backgroundColor: Colors.green, // Cor do Society
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text("Fala, ${user.nome}!", style: const TextStyle(fontSize: 24)),
            const Text("Bora marcar uma pelada?"),
          ],
        ),
      ),
    );
  }
}
