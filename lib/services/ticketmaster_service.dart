import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/evento_model.dart';

/// Servicio para consumir la API pública de Ticketmaster Discovery v2.
class TicketmasterService {
  /// Reemplaza este valor con tu Consumer Key obtenida en https://developer.ticketmaster.com/
  static const String apiKey = 'TU_CONSUMER_KEY_AQUI';

  static const String _baseUrl =
      'https://app.ticketmaster.com/discovery/v2/events.json';

  /// Consulta eventos en la API de Ticketmaster permitiendo filtrar por:
  /// - Coordenadas (latitud, longitud) y radio mínimo de 5 km
  /// - Ciudad (city)
  /// - Categoría (classificationName: Music, Sports, Arts & Theatre, etc.)
  /// - Palabra clave (keyword)
  Future<List<EventoModel>> buscarEventos({
    double? latitud,
    double? longitud,
    int radioKm = 50,
    String? ciudad,
    String? categoria,
    String? palabraClave,
    String? customApiKey,
  }) async {
    final String claveActiva =
        (customApiKey != null && customApiKey.trim().isNotEmpty)
            ? customApiKey.trim()
            : apiKey;

    // Garantizar que el radio mínimo sea de 5 km según los requisitos funcionales
    final int radioEfectivo = radioKm < 5 ? 5 : radioKm;

    // Si aún no se ha configurado una API Key real, devolvemos eventos de demostración
    // basados en el JSON oficial del documento para poder probar el mapa interactivo de inmediato.
    if (claveActiva == '' || claveActiva.isEmpty) {
      return _obtenerEventosDemostracion(
        latitud: latitud ?? 6.2442,
        longitud: longitud ?? -75.5812,
        ciudad: ciudad,
        categoria: categoria,
        palabraClave: palabraClave,
      );
    }

    final Map<String, String> queryParams = {
      'apikey': claveActiva,
      'size': '50',
      'unit': 'km',
      'radius': radioEfectivo.toString(),
    };

    // Si el usuario escribe una ciudad explícita (ej. Medellin, New York, Miami), filtramos por ciudad;
    // de lo contrario, filtramos por las coordenadas actuales del GPS (latlong).
    if (ciudad != null && ciudad.trim().isNotEmpty) {
      queryParams['city'] = ciudad.trim();
    } else if (latitud != null && longitud != null) {
      queryParams['latlong'] = '$latitud,$longitud';
    }

    if (categoria != null &&
        categoria.trim().isNotEmpty &&
        categoria != 'Todas') {
      queryParams['classificationName'] = categoria.trim();
    }

    if (palabraClave != null && palabraClave.trim().isNotEmpty) {
      queryParams['keyword'] = palabraClave.trim();
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      // En Ticketmaster, cuando no hay resultados, el nodo '_embedded' no viene en el JSON
      if (!data.containsKey('_embedded')) {
        return [];
      }

      final embedded = data['_embedded'] as Map<String, dynamic>;
      final List<dynamic> eventsJson = embedded['events'] as List<dynamic>? ?? [];

      final List<EventoModel> eventos = eventsJson
          .map((item) => EventoModel.fromJson(item as Map<String, dynamic>))
          .where((evento) => evento.tieneCoordenadasValidas)
          .toList();

      return eventos;
    } else if (response.statusCode == 401) {
      throw Exception(
        'API Key inválida (Error 401). Verifica tu Consumer Key de Ticketmaster.',
      );
    } else {
      throw Exception(
        'Error al consultar Ticketmaster (Código ${response.statusCode}).',
      );
    }
  }

  /// Eventos de respaldo con la estructura exacta del PDF (incluyendo World Cup: Match 49 Group C - Scotland vs Brazil)
  /// ubicados alrededor de la posición actual del usuario para pruebas cuando no se ha ingresado la Consumer Key.
  List<EventoModel> _obtenerEventosDemostracion({
    required double latitud,
    required double longitud,
    String? ciudad,
    String? categoria,
    String? palabraClave,
  }) {
    final List<EventoModel> demo = [
      EventoModel(
        id: 'Z7r9jZ1A743fw',
        nombre: 'World Cup: Match 49 Group C - Scotland vs Brazil',
        fecha: '2026-06-24',
        horario: '18:00',
        estado: 'onsale',
        categoria: 'Sports',
        nombreLugar: 'Hard Rock Stadium / Fan Fest Local',
        ciudad: ciudad?.isNotEmpty == true ? ciudad! : 'Medellín',
        direccion: 'Calle 50 # 46-36',
        latitud: latitud + 0.0035,
        longitud: longitud + 0.0025,
        url: 'https://www.ticketmaster.com/event/Z7r9jZ1A743fw',
      ),
      EventoModel(
        id: 'TM-DEMO-02',
        nombre: 'Concierto Sinfónico & Rock en Vivo',
        fecha: '2026-11-28',
        horario: '20:00',
        estado: 'onsale',
        categoria: 'Music',
        nombreLugar: 'Teatro Metropolitano',
        ciudad: ciudad?.isNotEmpty == true ? ciudad! : 'Medellín',
        direccion: 'Calle 41 # 57-30',
        latitud: latitud - 0.0042,
        longitud: longitud - 0.0031,
      ),
      EventoModel(
        id: 'TM-DEMO-03',
        nombre: 'Festival de Cultura y Artes Escénicas',
        fecha: '2026-12-05',
        horario: '16:30',
        estado: 'onsale',
        categoria: 'Arts & Theatre',
        nombreLugar: 'Centro Cultural Parque Explora',
        ciudad: ciudad?.isNotEmpty == true ? ciudad! : 'Medellín',
        direccion: 'Carrera 52 # 73-75',
        latitud: latitud + 0.0060,
        longitud: longitud - 0.0040,
      ),
    ];

    return demo.where((e) {
      final cumpleCategoria = categoria == null ||
          categoria.isEmpty ||
          categoria == 'Todas' ||
          e.categoria.toLowerCase() == categoria.toLowerCase();
      final cumplePalabra = palabraClave == null ||
          palabraClave.trim().isEmpty ||
          e.nombre.toLowerCase().contains(palabraClave.toLowerCase());
      return cumpleCategoria && cumplePalabra;
    }).toList();
  }
}
