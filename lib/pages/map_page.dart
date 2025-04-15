// Full Updated MapPage with Performance & UX Improvements
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const String MAPBOX_STYLE = 'mapbox://styles/mapbox/light-v10';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MapboxMapController? _mapController;
  LatLng? _currentLocation;
  Position? _lastPosition;
  List<Map<String, dynamic>> _publicReports = [];
  Map<String, dynamic>? _selectedReport;

  bool _isLoading = true;
  bool _isLoadingReports = false;
  bool _isTracking = true;
  bool _markersAdded = false;
  double _zoom = 14;
  double _tilt = 30;
  double _bearing = 0;
  String? _errorMessage;

  final GlobalKey _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _fetchPublicReports();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled.');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _lastPosition = position;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _moveCamera();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPublicReports() async {
    setState(() {
      _isLoadingReports = true;
      _markersAdded = false;
    });
    try {
      final response = await Supabase.instance.client
          .from('reports')
          .select()
          .eq('is_public', true)
          .order('report_date', ascending: false);
      setState(() {
        _publicReports = List<Map<String, dynamic>>.from(response);
        _isLoadingReports = false;
      });
      if (_mapController != null) _addReportMarkers();
    } catch (e) {
      setState(() {
        _isLoadingReports = false;
      });
    }
  }

  void _addReportMarkers() {
    if (_mapController == null || _markersAdded) return;
    _mapController!.clearSymbols();
    for (var report in _publicReports) {
      final lat = (report['latitude'] as num?)?.toDouble();
      final lng = (report['longitude'] as num?)?.toDouble();
      final sev = (report['severity'] as num?)?.toDouble() ?? 0.0;
      if (lat == null || lng == null) continue;
      final color = _colorToHex(_getSeverityColor(sev));
      _mapController!.addSymbol(SymbolOptions(
        geometry: LatLng(lat, lng),
        iconSize: 2.0,
        iconImage: "circle-11",
        textField: '●',
        textSize: 24.0,
        textColor: color,
        textOffset: const Offset(0, 0),
      ));
    }
    _markersAdded = true;
  }

  Color _getSeverityColor(double s) =>
      s <= 0.3 ? Colors.green : s <= 0.7 ? Colors.orange : Colors.red;
  String _colorToHex(Color c) => '#${c.value.toRadixString(16).substring(2)}';

  void _showReportPopup(Map<String, dynamic> report) {
    if (_selectedReport != null && _selectedReport!['id'] == report['id']) return;
    setState(() => _selectedReport = report);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Report: ${report['report'] ?? 'No description'}'),
            Text('Date: ${report['report_date'] ?? 'N/A'}'),
            Text('Severity: ${(report['severity'] ?? 0).toStringAsFixed(2)}'),
            Text('Location: ${report['latitude']}, ${report['longitude']}'),
          ],
        ),
      ),
    ).whenComplete(() => setState(() => _selectedReport = null));
  }

  void _moveCamera() {
    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentLocation!, zoom: _zoom, bearing: _bearing, tilt: _tilt),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = const LatLng(53.3498, -6.2603);
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Map View'),
        backgroundColor: const Color(0xFF1F8DED),
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.location_on : Icons.location_off),
            onPressed: () => setState(() => _isTracking = !_isTracking),
          )
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(onPressed: _determinePosition, child: const Text('Retry')),
                ],
              ),
            )
          else
            MapboxMap(
              key: _mapKey,
              accessToken: dotenv.env['MAPBOX_ACCESS_TOKEN']!,
              styleString: MAPBOX_STYLE,
              initialCameraPosition: CameraPosition(target: _currentLocation ?? fallback, zoom: _zoom),
              onMapCreated: (controller) => setState(() => _mapController = controller),
              onStyleLoadedCallback: () => _addReportMarkers(),
              onMapClick: (point, coords) {
                final near = _publicReports.firstWhere(
                  (r) => _calculateDistance(coords.latitude, coords.longitude, r['latitude'], r['longitude']) < 5,
                  orElse: () => {},
                );
                if (near.isNotEmpty) _showReportPopup(near);
              },
              myLocationEnabled: true,
              myLocationTrackingMode: _isTracking
                  ? MyLocationTrackingMode.Tracking
                  : MyLocationTrackingMode.None,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _determinePosition,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double? lat2, double? lon2) {
    if (lat2 == null || lon2 == null) return double.infinity;
    const R = 6371e3;
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final deltaPhi = (lat2 - lat1) * math.pi / 180;
    final deltaLambda = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) * math.cos(phi2) *
            math.sin(deltaLambda / 2) * math.sin(deltaLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
}
