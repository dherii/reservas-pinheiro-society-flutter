import 'package:flutter/material.dart';

// 1. O Ponto de Partida
// Todo app começa na função main(). O runApp() "infla" o seu widget raiz na tela.
void main() {
  runApp(const PinheiroSocietyApp());
}

// 2. O Widget Raiz (Root)
// Este é o "Gerente" do app. Ele define o título, tema e qual é a primeira tela.
class PinheiroSocietyApp extends StatelessWidget {
  const PinheiroSocietyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reservas Pinheiro Society',
      debugShowCheckedModeBanner: false, // Remove aquela faixinha "DEBUG" no canto
      
      // Configuração de Cores e Estilo
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), // Verde futebol!
        useMaterial3: true, // Usa o design system mais novo do Google
      ),
      
      // Qual tela aparece primeiro?
      home: const TelaExemplo(),
    );
  }
}

// 3. Uma Tela de Exemplo (Scaffold)
// Enquanto o MaterialApp é o App inteiro, o Scaffold é o esqueleto de UMA página.
class TelaExemplo extends StatelessWidget {
  const TelaExemplo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Pinheiro Society Admin'),
      ),
      
      // Corpo da página
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.sports_soccer, size: 100, color: Colors.green),
            SizedBox(height: 20), // Espaçamento invisível
            Text(
              'Bora pro jogo!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}