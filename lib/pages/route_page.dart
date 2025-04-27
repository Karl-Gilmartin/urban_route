import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:urban_route/main.dart';
import 'dart:math' show min, max;

class RoutePage extends StatefulWidget {
  final Map<String, dynamic> startLocation;
  final Map<String, dynamic> destinationLocation;
  final Map<String, dynamic> routeData;

  const RoutePage({
    super.key,
    required this.startLocation,
    required this.destinationLocation,
    required this.routeData,
  });

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  MapboxMapController? mapController;
  bool _isMapReady = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    if (_isDisposed) return;
    
    final accessToken = dotenv.get('MAPBOX_ACCESS_TOKEN');
    if (accessToken.isEmpty) {
      print('ERROR: Mapbox access token is empty!');
      return;
    }

    if (mounted) {
      setState(() {
        _isMapReady = true;
      });
    }
  }

  void _onMapCreated(MapboxMapController controller) {
    if (_isDisposed) return;
    mapController = controller;
  }

  void _onStyleLoaded() {
    if (_isDisposed) return;
    _addRouteToMap();
  }

  Future<void> _addRouteToMap() async {
    if (_isDisposed || mapController == null) {
      print('Map controller is null or widget is disposed');
      return;
    }

    try {
      final coordinates = widget.routeData['paths']?[0]?['points']?['coordinates'] as List?;
      if (coordinates == null) {
        print('No coordinates found in route data');
        return;
      }

      final List<LatLng> routePoints = coordinates.map((coord) {
        return LatLng(coord[1].toDouble(), coord[0].toDouble());
      }).toList();

      print('Created ${routePoints.length} route points');
      if (routePoints.isEmpty) {
        print('No valid route points to display');
        return;
      }

      if (_isDisposed) return;

      // Create a GeoJSON feature for the route
      final routeFeature = {
        'type': 'Feature',
        'properties': {},
        'geometry': {
          'type': 'LineString',
          'coordinates': routePoints.map((point) => [point.longitude, point.latitude]).toList(),
        },
      };

      // Add the route as a source
      await mapController!.addSource(
        'route',
        GeojsonSourceProperties(
          data: routeFeature,
        ),
      );

      if (_isDisposed) return;

      // Add a layer for the route line
      await mapController!.addLayer(
        'route',
        'route-line',
        LineLayerProperties(
          lineColor: '#00FFFF',
          lineWidth: 4.0,
          lineJoin: 'round',
          lineCap: 'round',
        ),
      );

      if (_isDisposed) return;

      // Add start marker
      await mapController!.addSymbol(
        SymbolOptions(
          geometry: routePoints.first,
          iconImage: 'marker-15',
          iconSize: 1.5,
          iconColor: '#00FF00',
        ),
      );

      if (_isDisposed) return;

      // Add end marker
      await mapController!.addSymbol(
        SymbolOptions(
          geometry: routePoints.last,
          iconImage: 'marker-15',
          iconSize: 1.5,
          iconColor: '#FF0000',
        ),
      );

      if (_isDisposed) return;

      // Fit the map to show the entire route
      final bounds = LatLngBounds(
        southwest: LatLng(
          min(widget.startLocation['latitude'], widget.destinationLocation['latitude']),
          min(widget.startLocation['longitude'], widget.destinationLocation['longitude']),
        ),
        northeast: LatLng(
          max(widget.startLocation['latitude'], widget.destinationLocation['latitude']),
          max(widget.startLocation['longitude'], widget.destinationLocation['longitude']),
        ),
      );

      await mapController!.moveCamera(
        CameraUpdate.newLatLngBounds(bounds),
      );

      if (!_isDisposed) {
        print('Route added successfully');
      }
    } catch (e) {
      if (!_isDisposed) {
        print('Error adding route to map: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessToken = dotenv.get('MAPBOX_ACCESS_TOKEN');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        backgroundColor: AppColors.deepBlue,
      ),
      body: _isMapReady
          ? MapboxMap(
              accessToken: accessToken,
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: _onStyleLoaded,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  (widget.startLocation['latitude'] + widget.destinationLocation['latitude']) / 2,
                  (widget.startLocation['longitude'] + widget.destinationLocation['longitude']) / 2,
                ),
                zoom: 12.0,
              ),
              styleString: MapboxStyles.MAPBOX_STREETS,
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
