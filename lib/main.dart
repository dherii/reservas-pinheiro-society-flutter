import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:reservas_pinheirosociety/screens/client_web/client_home_screen.dart';
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

      // CONFIGURAÇÃO DE TEMA
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),

      // CONFIGURAÇÃO DE IDIOMA (PT-BR)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],

      // 🚦 O Roteamento Inteligente
      // Se for no navegador (cliente), vai para a vitrine.
      // Se for no app instalado, passa pelo Portão de Autenticação (Login -> AdminHomeScreen)
      home: kIsWeb ? ClientHomeScreen() : const AuthGate(),
    );
  }
}
