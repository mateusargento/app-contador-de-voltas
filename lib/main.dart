import 'package:flutter/material.dart';
import 'package:contadordevoltaspp/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contador de Voltas',
      theme: ThemeData(
        // Cores padrão
        colorScheme: const ColorScheme.light(
          primary: Color.fromRGBO(156, 255, 46, 1),
        ),
        useMaterial3: true,

        // Estilo dos botões
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            backgroundColor: Colors.grey[50],
            side: const BorderSide(
              width: 5,
              color: Colors.black,
              style: BorderStyle.solid,
            ),
          ),
        ),

        // Estilo dos textos
        textTheme: const TextTheme(
          // Título Grande
          titleLarge: TextStyle(
            fontSize: 96,
            fontFamily: 'InterTight',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w900,
          ),

          // Título médio
          titleMedium: TextStyle(
            fontSize: 28,
            fontFamily: 'InterTight',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w900,
          ),

          // Texto médio
          bodyMedium: TextStyle(
            fontSize: 20,
            fontFamily: 'InterTight',
            fontWeight: FontWeight.w500,
          ),

          // Texto pequeno
          bodySmall: TextStyle(
            fontSize: 14,
            fontFamily: 'InterTight',
            fontWeight: FontWeight.w200,
          ),
        ),
      ),
      home: const Home(),
    );
  }
}
