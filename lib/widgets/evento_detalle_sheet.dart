import 'package:flutter/material.dart';
import '../models/evento_model.dart';

/// BottomSheet que muestra la información del evento al tocar su marcador en el mapa,
/// siguiendo exactamente el diseño de la captura de pantalla del documento guía.
class EventoDetalleSheet extends StatelessWidget {
  final EventoModel evento;

  const EventoDetalleSheet({
    super.key,
    required this.evento,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFFDF7FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            evento.nombre,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Fecha: ${evento.fecha}',
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            'Horario: ${evento.horario}',
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            'Estado: ${evento.estado}',
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          if (evento.nombreLugar.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Lugar: ${evento.nombreLugar}${evento.ciudad.isNotEmpty ? " (${evento.ciudad})" : ""}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}
