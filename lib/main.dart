import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:reservas_pinheirosociety/screens/auth/login_screen.dart';
import 'package:reservas_pinheirosociety/screens/auth_gate.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PinheiroSocietyApp());
}

class PinheiroSocietyApp extends StatelessWidget {
  const PinheiroSocietyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reservas Pinheiro Society',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),

      home: const AuthGate(),
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
