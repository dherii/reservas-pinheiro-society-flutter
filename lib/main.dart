import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <--- Importante para Pt-Br
import 'package:reservas_pinheirosociety/screens/home_screen.dart';
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
          brightness: Brightness.light, // Força modo claro por enquanto
        ),
        useMaterial3: true,
        // Dica visual: Deixa os Inputs com um estilo mais moderno por padrão
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),

      // CONFIGURAÇÃO DE IDIOMA (PT-BR) 🇧🇷
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations
            .delegate, // Importante para o DatePicker do iOS/Cupertino
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Português do Brasil
      ],

      home: const HomeScreen(),
    );
  }
}
