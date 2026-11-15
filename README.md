# IUPB - Programación de Dispositivos Móviles (Evaluación 4)
## Mapa Explorador de Eventos Cercanos (Ticketmaster API + FlutterMap + Geolocator)

Aplicación desarrollada en **Flutter** para la asignatura **Programación de Dispositivos Móviles** de la **Institución Universitaria Pascual Bravo**, siguiendo la estructura modular del repositorio de referencia (`IUPB_PDM_MapaExploradorLocal`) y las especificaciones de la **Evaluación 4**.

---

## Estructura del Proyecto

```text
IUPB_PDM_EventosCercanos/
├── android/
│   └── app/src/main/AndroidManifest.xml   # Permisos de INTERNET y GPS (FINE/COARSE LOCATION)
├── ios/
│   └── Runner/Info.plist                  # Permisos NSLocationWhenInUseUsageDescription
├── lib/
│   ├── main.dart                          # Punto de entrada de la aplicación
│   ├── models/
│   │   └── evento_model.dart              # Parseo del JSON profundo (_embedded -> events -> venues)
│   ├── services/
│   │   ├── location_service.dart          # Gestión de permisos y ubicación actual con Geolocator
│   │   └── ticketmaster_service.dart      # Consumo de Ticketmaster Discovery API v2 y filtros
│   ├── screens/
│   │   └── mapa_eventos_screen.dart       # Interfaz Scaffold -> AppBar -> Stack -> FlutterMap + CircularProgressIndicator
│   └── widgets/
│       └── evento_detalle_sheet.dart      # Modal inferior con Fecha, Horario y Estado del evento
├── pubspec.yaml                           # Dependencias: flutter_map, latlong2, geolocator, http
└── README.md                              # Documentación del proyecto
```

---

## Requisitos Funcionales Implementados

1. **Ubicación actual con `geolocator` y manejo de permisos:**
   - En `lib/services/location_service.dart` se verifica que el GPS esté encendido y se solicitan los permisos `LocationPermission` de forma segura.
2. **Marcador de ubicación del usuario y marcadores de eventos:**
   - El usuario se visualiza con un marcador azul (`Icons.person_pin_circle`) y cada evento cercano con un marcador rojo (`Icons.location_on`) sobre `FlutterMap` (OpenStreetMap).
3. **Interacción con los marcadores de eventos:**
   - Al tocar cualquier marcador de evento, se despliega un `ModalBottomSheet` (`EventoDetalleSheet`) con el mismo diseño del documento guía:
     - **Nombre del evento** (ej. *World Cup: Match 49 Group C - Scotland vs Brazil*)
     - **Fecha:** `YYYY-MM-DD`
     - **Horario:** `HH:mm`
     - **Estado:** `onsale`
4. **Consumo de la API de Ticketmaster y filtros:**
   - Endpoint: `https://app.ticketmaster.com/discovery/v2/events.json`
   - Soporta filtrado por **ubicación y radio mínimo de 5 km** (`latlong`, `radius`, `unit=km`), **ciudad** (`city`), **categoría** (`classificationName`) y **palabra clave** (`keyword`).

---

## Configuración de la API Key de Ticketmaster

1. Ingresa a [https://developer.ticketmaster.com/](https://developer.ticketmaster.com/) e inicia sesión.
2. En **Explore Your Apps**, copia tu **Consumer Key**.
3. Abre el archivo `lib/services/ticketmaster_service.dart` y reemplaza la constante:
   ```dart
   static const String apiKey = 'TU_CONSUMER_KEY_AQUI';
   ```
   *(También puedes pegarla directamente desde la aplicación tocando el ícono de filtros en la esquina superior derecha de la barra de navegación).*
4. Ejecuta el proyecto:
   ```bash
   flutter pub get
   flutter run
   ```
