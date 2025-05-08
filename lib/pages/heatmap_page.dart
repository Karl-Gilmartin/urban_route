import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../components/report_popup.dart';
import '../schema/database_schema.dart';
import '../main.dart';

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
    {0.25: Colors.blue, 0.55: Colors.red, 0.85: Colors.pink, 1.0: Colors.purple},
  ];
  
  // Custom gradient for heat intensity
  final Map<double, MaterialColor> _customGradient1 = {
    0.0: Colors.green,
    0.5: Colors.yellow,
    0.75: Colors.orange,
    1.0: Colors.red,
  };
  
  // Another custom gradient
  final Map<double, MaterialColor> _customGradient2 = {
    0.0: Colors.blue,
    0.4: Colors.cyan,
    0.6: Colors.yellow,
    0.8: Colors.orange,
    1.0: Colors.red,
  };
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
      // Join reports with report_locations to get the lat/long data
      final response = await Supabase.instance.client
          .from(DatabaseSchema.reports)
          .select('''
            ${Reports.id},
            ${Reports.userId},
            ${Reports.severity},
            ${Reports.status},
            ${Reports.isPublic},
            ${Reports.osmWayId},
            ${Reports.locationId},
            ${Reports.submittedAt},
            report_locations!location_id(
              latitude,
              longitude,
              address,
              osm_id
            ),
            report_contents!report_contents_report_id_fkey(
              report_text,
              language
            )
          ''')
          .eq(Reports.isPublic, true)
          .order(Reports.submittedAt, ascending: false);
      
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
      // Extract location data from the nested report_locations object
      final locationData = report['report_locations'];
      if (locationData == null) continue;
      
      final lat = (locationData['latitude'] as num?)?.toDouble();
      final lng = (locationData['longitude'] as num?)?.toDouble();
      
      // Get severity from the report
      var sev = (report[Reports.severity] as num?)?.toDouble() ?? 0.0;
      
      // Amplify the weight to make heat more intense
      if (sev > 0) {
        sev = sev * 1.5;
      }
      
      if (lat == null || lng == null) continue;

      _heatmapData.add(WeightedLatLng(LatLng(lat, lng), sev));
      
      // Add some extra points nearby for more intensity at high severity locations
      if (sev > 3.0) {
        const delta = 0.0001; // Small geographic offset
        _heatmapData.add(WeightedLatLng(LatLng(lat + delta, lng), sev * 0.7));
        _heatmapData.add(WeightedLatLng(LatLng(lat - delta, lng), sev * 0.7));
        _heatmapData.add(WeightedLatLng(LatLng(lat, lng + delta), sev * 0.7));
        _heatmapData.add(WeightedLatLng(LatLng(lat, lng - delta), sev * 0.7));
      }
    }
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rebuildStream.add(null);
    });
  }

  void _toggleGradient() {
    setState(() {
      _gradientIndex = (_gradientIndex + 1) % 4;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rebuildStream.add(null);
      });
    });
  }

  void _showReportPopup(Map<String, dynamic> report) {
    // Extract content from the nested structure
    final reportContents = report['report_contents'];
    String reportText = 'No content available';
    
    if (reportContents is List && reportContents.isNotEmpty) {
      reportText = reportContents[0]['report_text'] ?? 'No content available';
    }
    
    // Create a flattened report object for the popup
    final flattenedReport = {
      'id': report[Reports.id],
      'severity': report[Reports.severity],
      'status': report[Reports.status],
      'report': reportText,
      'is_public': report[Reports.isPublic],
      'latitude': report['report_locations']?['latitude'],
      'longitude': report['report_locations']?['longitude'],
    };
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => ReportPopup(
        report: flattenedReport,
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
        backgroundColor: AppColors.deepBlue,
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
                      gradient: _gradientIndex < 2 ? _gradients[_gradientIndex] : 
                              _gradientIndex == 2 ? _customGradient1 : _customGradient2,
                      minOpacity: 0.2,
                      radius: 20,
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
        ],
      ),
      // floatingActionButton: Column(
      //   mainAxisAlignment: MainAxisAlignment.end,
      //   children: [
      //     FloatingActionButton(
      //       heroTag: 'gradient_fab',
      //       onPressed: _toggleGradient,
      //       backgroundColor: AppColors.brightCyan,
      //       child: const Icon(Icons.palette),
      //     ),
      //     const SizedBox(height: 16),
      //     FloatingActionButton(
      //       heroTag: 'location_fab_heatmap',
      //       onPressed: _determinePosition,
      //       backgroundColor: AppColors.brightCyan,
      //       child: const Icon(Icons.my_location),
      //     ),
      //   ],
      // ),
    );
  }
} 