import 'package:flutter/material.dart';
import 'screens/mapa_eventos_screen.dart';

void main() {
  runApp(const EventosCercanosApp());
}

class EventosCercanosApp extends StatelessWidget {
  const EventosCercanosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventos Cercanos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MapaEventosScreen(),
    );
  }
}
