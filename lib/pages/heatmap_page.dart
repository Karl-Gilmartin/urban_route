import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../components/report_popup.dart';

class HeatmapPage extends StatefulWidget {
  const HeatmapPage({super.key});

  @override
  State<HeatmapPage> createState() => _HeatmapPageState();
}

class _HeatmapPageState extends State<HeatmapPage> {
  LatLng? _currentLocation;
  List<Map<String, dynamic>> _publicReports = [];
  List<WeightedLatLng> _heatmapData = [];
  bool _isLoading = true;
  bool _isLoadingReports = false;
  String? _errorMessage;
  double _zoom = 14.0;
  final MapController _mapController = MapController();
  final StreamController<void> _rebuildStream = StreamController.broadcast();

  final List<Map<double, MaterialColor>> _gradients = [
    HeatMapOptions.defaultGradient,
    {0.25: Colors.blue, 0.55: Colors.red, 0.85: Colors.pink, 1.0: Colors.purple}
  ];
  int _gradientIndex = 0;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _fetchPublicReports();
  }

  @override
  void dispose() {
    _rebuildStream.close();
    super.dispose();
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
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      // Delay the camera move to ensure the map is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _moveCamera();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPublicReports() async {
    setState(() => _isLoadingReports = true);
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
      _updateHeatmapData();
    } catch (e) {
      print('Error fetching reports: $e');
      setState(() => _isLoadingReports = false);
    }
  }

  void _updateHeatmapData() {
    _heatmapData.clear();
    for (var report in _publicReports) {
      final lat = (report['latitude'] as num?)?.toDouble();
      final lng = (report['longitude'] as num?)?.toDouble();
      final sev = (report['severity'] as num?)?.toDouble() ?? 0.0;
      if (lat == null || lng == null) continue;

      _heatmapData.add(WeightedLatLng(LatLng(lat, lng), sev));
    }
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rebuildStream.add(null);
    });
  }

  void _toggleGradient() {
    setState(() {
      _gradientIndex = _gradientIndex == 0 ? 1 : 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rebuildStream.add(null);
      });
    });
  }

  void _showReportPopup(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => ReportPopup(
        report: report,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _moveCamera() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, _zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallbackLocation = const LatLng(53.3498, -6.2603);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heatmap View'),
        backgroundColor: const Color(0xFF1F8DED),
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
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? fallbackLocation,
                initialZoom: _zoom,
                onTap: (tapPosition, point) {
                  // Find the nearest report within 50 meters
                  for (var report in _publicReports) {
                    final lat = (report['latitude'] as num?)?.toDouble();
                    final lng = (report['longitude'] as num?)?.toDouble();
                    if (lat == null || lng == null) continue;

                    final reportLatLng = LatLng(lat, lng);
                    final distance = const Distance().as(
                      LengthUnit.Meter,
                      point,
                      reportLatLng,
                    );

                    if (distance <= 50) {
                      _showReportPopup(report);
                      break;
                    }
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                if (_heatmapData.isNotEmpty)
                  HeatMapLayer(
                    heatMapDataSource: InMemoryHeatMapDataSource(data: _heatmapData),
                    heatMapOptions: HeatMapOptions(
                      gradient: _gradients[_gradientIndex],
                      minOpacity: 0.1,
                    ),
                    reset: _rebuildStream.stream,
                  ),
              ],
            ),
          if (_isLoadingReports)
            const Positioned(
              top: 16,
              left: 16,
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading reports...'),
                    ],
                  ),
                ),
              ),
            ),
          // Debug overlay
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Reports: ${_publicReports.length}'),
                    Text('Zoom: ${_zoom.toStringAsFixed(1)}'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'gradient_fab',
            onPressed: _toggleGradient,
            child: const Icon(Icons.palette),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'location_fab_heatmap',
            onPressed: _determinePosition,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
} 