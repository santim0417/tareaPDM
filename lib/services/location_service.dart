import 'package:geolocator/geolocator.dart';

/// Servicio encargado de gestionar los permisos de GPS y obtener la ubicación actual del usuario.
class LocationService {
  /// Verifica que el servicio GPS esté activo, solicita permisos y retorna la posición actual.
  Future<Position> obtenerUbicacionActual() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Verificar si los servicios de ubicación están habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Los servicios de ubicación (GPS) están desactivados. Por favor actívalos en el dispositivo o emulador.',
      );
    }

    // 2. Verificar permisos de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Los permisos de ubicación fueron denegados por el usuario.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Los permisos de ubicación están denegados permanentemente. Habilítalos desde la configuración.',
      );
    }

    // 3. Retornar la ubicación actual con alta precisión
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
