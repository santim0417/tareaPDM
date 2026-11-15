/// Modelo que representa un evento obtenido desde el JSON profundo de Ticketmaster API v2.
class EventoModel {
  final String id;
  final String nombre;
  final String fecha;
  final String horario;
  final String estado;
  final String categoria;
  final String nombreLugar;
  final String ciudad;
  final String direccion;
  final double latitud;
  final double longitud;
  final String? url;

  EventoModel({
    required this.id,
    required this.nombre,
    required this.fecha,
    required this.horario,
    required this.estado,
    required this.categoria,
    required this.nombreLugar,
    required this.ciudad,
    required this.direccion,
    required this.latitud,
    required this.longitud,
    this.url,
  });

  /// Parsea el JSON profundo retornado por Ticketmaster Discovery API v2:
  /// _embedded -> events[] -> { name, dates: { start: { localDate, localTime }, status: { code } },
  /// _embedded: { venues: [ { name, city: { name }, address: { line1 }, location: { latitude, longitude } } ] } }
  factory EventoModel.fromJson(Map<String, dynamic> json) {
    // 1. Fechas, horario y estado (dates -> start / status)
    final dates = json['dates'] as Map<String, dynamic>? ?? {};
    final start = dates['start'] as Map<String, dynamic>? ?? {};
    final status = dates['status'] as Map<String, dynamic>? ?? {};

    final String localDate = start['localDate']?.toString() ?? 'Por definir';
    String localTime = start['localTime']?.toString() ?? 'Por definir';
    // Formatear HH:mm:ss a HH:mm como se muestra en la guía (ej. 18:00)
    if (localTime.length >= 5 && localTime.contains(':')) {
      localTime = localTime.substring(0, 5);
    }
    final String statusCode = status['code']?.toString() ?? 'desconocido';

    // 2. Categoría (classifications -> [0] -> segment -> name)
    String categoriaNombre = 'General';
    final classifications = json['classifications'] as List<dynamic>?;
    if (classifications != null && classifications.isNotEmpty) {
      final firstClass = classifications.first as Map<String, dynamic>? ?? {};
      final segment = firstClass['segment'] as Map<String, dynamic>?;
      if (segment != null && segment['name'] != null) {
        categoriaNombre = segment['name'].toString();
      }
    }

    // 3. Ubicación profunda (_embedded -> venues -> [0] -> location: { latitude, longitude })
    String venueName = 'Lugar no especificado';
    String cityName = '';
    String addressLine = '';
    double lat = 0.0;
    double lng = 0.0;

    final embedded = json['_embedded'] as Map<String, dynamic>?;
    final venues = embedded?['venues'] as List<dynamic>?;
    if (venues != null && venues.isNotEmpty) {
      final venue = venues.first as Map<String, dynamic>? ?? {};
      venueName = venue['name']?.toString() ?? venueName;

      final cityObj = venue['city'] as Map<String, dynamic>?;
      cityName = cityObj?['name']?.toString() ?? '';

      final addressObj = venue['address'] as Map<String, dynamic>?;
      addressLine = addressObj?['line1']?.toString() ?? '';

      final locationObj = venue['location'] as Map<String, dynamic>?;
      if (locationObj != null) {
        lat = double.tryParse(locationObj['latitude']?.toString() ?? '') ?? 0.0;
        lng = double.tryParse(locationObj['longitude']?.toString() ?? '') ?? 0.0;
      }
    }

    // Respaldo en caso de que el evento traiga 'location' en la raíz
    if (lat == 0.0 && lng == 0.0 && json['location'] != null) {
      final loc = json['location'] as Map<String, dynamic>;
      lat = double.tryParse(loc['latitude']?.toString() ?? '') ?? 0.0;
      lng = double.tryParse(loc['longitude']?.toString() ?? '') ?? 0.0;
    }

    return EventoModel(
      id: json['id']?.toString() ?? '',
      nombre: json['name']?.toString() ?? 'Evento sin nombre',
      fecha: localDate,
      horario: localTime,
      estado: statusCode,
      categoria: categoriaNombre,
      nombreLugar: venueName,
      ciudad: cityName,
      direccion: addressLine,
      latitud: lat,
      longitud: lng,
      url: json['url']?.toString(),
    );
  }

  bool get tieneCoordenadasValidas => latitud != 0.0 && longitud != 0.0;
}
