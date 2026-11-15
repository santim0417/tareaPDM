import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/evento_model.dart';
import '../services/location_service.dart';
import '../services/ticketmaster_service.dart';
import '../widgets/evento_detalle_sheet.dart';

class MapaEventosScreen extends StatefulWidget {
  const MapaEventosScreen({super.key});

  @override
  State<MapaEventosScreen> createState() => _MapaEventosScreenState();
}

class _MapaEventosScreenState extends State<MapaEventosScreen> {
  final LocationService _locationService = LocationService();
  final TicketmasterService _ticketmasterService = TicketmasterService();
  final MapController _mapController = MapController();

  // Ubicación inicial por defecto (Medellín - Calle 50 / Carrera 46 como en la guía)
  LatLng _ubicacionUsuario = const LatLng(6.2486, -75.5658);
  bool _tieneUbicacionReal = false;
  bool _cargando = true;
  String? _mensajeError;

  List<EventoModel> _eventos = [];

  // Controladores para filtros de búsqueda (ciudad, categoría, palabra clave, radio >= 5 km y API Key)
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _palabraClaveController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  String _categoriaSeleccionada = 'Todas';
  double _radioKm = 25.0; // Radio mínimo de 5 km garantizado en el Slider

  final List<String> _categorias = const [
    'Todas',
    'Music',
    'Sports',
    'Arts & Theatre',
    'Film',
    'Miscellaneous',
  ];

  @override
  void initState() {
    super.initState();
    _inicializarMapaYEventos();
  }

  @override
  void dispose() {
    _ciudadController.dispose();
    _palabraClaveController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  /// Obtiene la ubicación actual del usuario usando geolocator y consulta los eventos en Ticketmaster.
  Future<void> _inicializarMapaYEventos() async {
    setState(() {
      _cargando = true;
      _mensajeError = null;
    });

    try {
      final posicion = await _locationService.obtenerUbicacionActual();
      _ubicacionUsuario = LatLng(posicion.latitude, posicion.longitude);
      _tieneUbicacionReal = true;
    } catch (e) {
      // Si el emulador no tiene GPS activo o se deniega el permiso, notificamos y usamos la ubicación base
      _mensajeError = e.toString().replaceFirst('Exception: ', '');
      _tieneUbicacionReal = false;
    }

    await _cargarEventos();
  }

  /// Consume el servicio de Ticketmaster aplicando los filtros activos.
  Future<void> _cargarEventos() async {
    setState(() {
      _cargando = true;
    });

    try {
      final eventosObtenidos = await _ticketmasterService.buscarEventos(
        latitud: _ubicacionUsuario.latitude,
        longitud: _ubicacionUsuario.longitude,
        radioKm: _radioKm.round(),
        ciudad: _ciudadController.text,
        categoria: _categoriaSeleccionada,
        palabraClave: _palabraClaveController.text,
        customApiKey: _apiKeyController.text,
      );

      if (!mounted) return;

      setState(() {
        _eventos = eventosObtenidos;
        _cargando = false;
      });

      // Si se buscó por otra ciudad (ej. New York o Miami) y hay resultados, movemos la cámara al primer evento
      if (_ciudadController.text.trim().isNotEmpty && _eventos.isNotEmpty) {
        final primerEvento = _eventos.first;
        _mapController.move(
          LatLng(primerEvento.latitud, primerEvento.longitud),
          13.0,
        );
      } else {
        _mapController.move(_ubicacionUsuario, 15.0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _mensajeError = e.toString().replaceFirst('Exception: ', '');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mensajeError ?? 'Error al cargar eventos')),
      );
    }
  }

  /// Muestra el detalle del evento al interactuar con su marcador en el mapa.
  void _mostrarDetalleEvento(EventoModel evento) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => EventoDetalleSheet(evento: evento),
    );
  }

  /// Abre un cuadro de diálogo para filtrar por Ciudad, Categoría, Palabra clave, Radio (mínimo 5 km) y Consumer Key.
  void _abrirModalFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtrar Eventos (Ticketmaster)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ciudadController,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad (ej. Medellin, New York, Miami)',
                        hintText: 'Vacío para usar tu ubicación GPS actual',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _categoriaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: _categorias
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ),
                          )
                          .toList(),
                      onChanged: (valor) {
                        if (valor != null) {
                          setModalState(() {
                            _categoriaSeleccionada = valor;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _palabraClaveController,
                      decoration: const InputDecoration(
                        labelText: 'Palabra clave (keyword)',
                        hintText: 'Ej. World Cup, Concert, Rock...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Radio de búsqueda: ${_radioKm.round()} km (Mínimo 5 km)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: _radioKm,
                      min: 5,
                      max: 200,
                      divisions: 39,
                      label: '${_radioKm.round()} km',
                      onChanged: (valor) {
                        setModalState(() {
                          _radioKm = valor;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Consumer Key (Opcional si ya está en código)',
                        hintText: 'Pega tu Consumer Key de Ticketmaster',
                        prefixIcon: Icon(Icons.vpn_key),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.filter_alt),
                        label: const Text('Aplicar Filtros y Buscar'),
                        onPressed: () {
                          Navigator.pop(context);
                          _cargarEventos();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Estructura exacta sugerida en el diagrama de la página 5:
    // Scaffold -> AppBar (Text('Eventos Cercanos')) -> Body -> Stack -> [FlutterMap, CircularProgressIndicator]
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos Cercanos'),
        actions: [
          IconButton(
            tooltip: 'Filtrar por ciudad, categoría, palabra clave o radio',
            icon: const Icon(Icons.tune),
            onPressed: _abrirModalFiltros,
          ),
          IconButton(
            tooltip: 'Actualizar ubicación GPS',
            icon: const Icon(Icons.my_location),
            onPressed: _inicializarMapaYEventos,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _ubicacionUsuario,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pascualbravo.iupb_pdm_eventos_cercanos',
              ),
              MarkerLayer(
                markers: [
                  // Marcador de la ubicación actual del usuario
                  Marker(
                    point: _ubicacionUsuario,
                    width: 50,
                    height: 50,
                    child: Tooltip(
                      message: _tieneUbicacionReal
                          ? 'Tu ubicación actual'
                          : 'Ubicación por defecto',
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blueAccent,
                        size: 44,
                      ),
                    ),
                  ),
                  // Marcadores de los eventos cercanos obtenidos de Ticketmaster
                  ..._eventos.map(
                    (evento) => Marker(
                      point: LatLng(evento.latitud, evento.longitud),
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _mostrarDetalleEvento(evento),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_cargando)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
