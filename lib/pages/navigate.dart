//  A page which takes in the user's destination and start point

import 'package:flutter/material.dart';
import 'package:urban_route/components/status_popup.dart';
import 'package:urban_route/main.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../components/route_summary_card.dart';
import '../components/walking_route_card.dart';
import 'route_page.dart';
import 'safe_route_page.dart';
class NavigatePage extends StatefulWidget {
  const NavigatePage({super.key});

  @override
  State<NavigatePage> createState() => _NavigatePageState();
}

class _NavigatePageState extends State<NavigatePage> {
  final TextEditingController _startPointController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _startLocation;
  Map<String, dynamic>? _destinationLocation;

  @override
  void dispose() {
    _startPointController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _geocodeAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'address': address,
        };
      }
      return null;
    } catch (e) {
      print('Geocoding error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchGraphHopperRoute(double startLat, double startLng, double endLat, double endLng) async {
    try {
      print('=== GRAPHHOPPER ROUTE FETCH STARTED ===');
      print('Start coordinates: $startLat, $startLng');
      print('End coordinates: $endLat, $endLng');
      
      final apiKey = dotenv.get('GRAPHHOPPER_API_KEY');
      if (apiKey.isEmpty) {
        print('ERROR: GraphHopper API key is empty!');
        return null;
      }
      print('API Key found: ${apiKey.substring(0, 5)}...');
      
      final uri = Uri.parse(
        'https://graphhopper.com/api/1/route?point=$startLat,$startLng&point=$endLat,$endLng&vehicle=foot&locale=en&points_encoded=false&key=$apiKey'
      );
      
      print('Making request to GraphHopper API...');
      final response = await http.get(uri);
      print('Response received. Status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('\n=== GRAPHHOPPER RESPONSE DATA ===');
        print('Full Response:');
        print(json.encode(data));
        print('\nRoute Details:');
        print('Status: ${data['info']?['status']}');
        print('Time: ${data['paths']?[0]?['time']} ms');
        print('Distance: ${data['paths']?[0]?['distance']} m');
        
        // Handle coordinates from the points object
        final coordinates = data['paths']?[0]?['points']?['coordinates'] as List?;
        if (coordinates != null) {
          print('Points: ${coordinates.length} points in route');
          print('\nRoute Points Sample:');
          for (var i = 0; i < min(5, coordinates.length); i++) {
            print('Point $i: ${coordinates[i]}');
          }
        }
        
        return data;
      } else {
        print('GraphHopper API error:');
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error in _fetchGraphHopperRoute: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // fetch safer route from my vps
  Future<Map<String, dynamic>?> _fetchSaferRoute(double startLat, double startLng, double endLat, double endLng) async {
  try {
    final uri = Uri.parse('http://144.91.67.206:8080/api/routes/calculate').replace(queryParameters: {
      'fromLat': startLat.toString(),
      'fromLon': startLng.toString(),
      'toLat': endLat.toString(),
      'toLon': endLng.toString(),
      'useSafetyWeights': 'true',
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Response received: $data');
      return data;
    } else {
      print('❌ Failed to fetch route: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('❌ Error fetching route: $e');
    return null;
  }
}

  Future<Map<String, dynamic>?> _getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are required to use this feature';
          });
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied';
        });
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': 'Using your location',
      };
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _errorMessage = 'Error getting location: $e';
      });
      return null;
    }
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final location = await _getCurrentLocation();
    
    if (location != null) {
      setState(() {
        _startPointController.text = 'Using your location';
        _startLocation = location;
      });
    } else {
      // Show error popup
      StatusPopup.showError(
        context: context,
        message: _errorMessage ?? 'Could not get your location',
        onButtonPressed: () {
          Navigator.of(context).pop(); // Close the dialog
        },
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _startNavigation() async {
    print('=== START NAVIGATION CALLED ===');
    
    final startPoint = _startPointController.text.trim();
    final destination = _destinationController.text.trim();
    print('Start Point: $startPoint');
    print('Destination: $destination');

    if (startPoint.isEmpty || destination.isEmpty) {
      print('Error: Empty start point or destination');
      setState(() {
        _errorMessage = 'Please enter both start point and destination';
      });
      
      // Show error popup
      StatusPopup.showError(
        context: context,
        message: _errorMessage!,
        onButtonPressed: () {
          Navigator.of(context).pop(); // Close the dialog
        },
      );
      
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Getting locations...');
      // If we're using current location, use the stored coordinates
      Map<String, dynamic>? startLocation = _startLocation;
      Map<String, dynamic>? destinationLocation;

      // Only geocode start point if we're not using current location
      if (startPoint != 'Using your location') {
        print('Geocoding start point...');
        startLocation = await _geocodeAddress(startPoint);
      } else {
        print('Using current location for start point');
      }

      // Always geocode destination
      print('Geocoding destination...');
      destinationLocation = await _geocodeAddress(destination);

      if (startLocation == null || destinationLocation == null) {
        print('Error: Could not get locations');
        setState(() {
          _errorMessage = 'Could not find coordinates for one or both addresses. Please check your inputs.';
        });
        
        // Show error popup
        StatusPopup.showError(
          context: context,
          message: _errorMessage!,
          onButtonPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        );
        
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Locations obtained successfully');
      print('Start Location: ${startLocation['latitude']}, ${startLocation['longitude']}');
      print('Destination: ${destinationLocation['latitude']}, ${destinationLocation['longitude']}');

      setState(() {
        _startLocation = startLocation;
        _destinationLocation = destinationLocation;
        _isLoading = false;
      });

      print('=== STARTING GRAPHHOPPER ROUTE FETCH ===');
      // Fetch the route from GraphHopper
      final routeData = await _fetchGraphHopperRoute(
        startLocation['latitude'],
        startLocation['longitude'],
        destinationLocation['latitude'],
        destinationLocation['longitude'],
      );

      // Fetch the safer route from my VPS
      final saferRouteData = await _fetchSaferRoute(
        startLocation['latitude'],
        startLocation['longitude'],
        destinationLocation['latitude'],
        destinationLocation['longitude'],
      );
      print('Safer Route Data Completed');
      print('=== FINISHED GRAPHHOPPER ROUTE FETCH ===');

      // Navigate to placeholder map page
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _PlaceholderMapPage(
            startPoint: startPoint,
            destination: destination,
            startLocation: startLocation!,
            destinationLocation: destinationLocation!,
            routeData: routeData,
            saferRouteData: saferRouteData,
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('Error in _startNavigation: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
      
      // Show error popup
      StatusPopup.showError(
        context: context,
        message: _errorMessage!,
        onButtonPressed: () {
          Navigator.of(context).pop(); // Close the dialog
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.deepBlue,
              AppColors.brightCyan.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Navigation',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your start point and destination',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  _buildInputField(_startPointController, 'Enter start point', Icons.location_on, isStartPoint: true),
                  const SizedBox(height: 16),
                  _buildInputField(_destinationController, 'Enter destination', Icons.flag),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _startNavigation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brightCyan,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.navigation),
                                SizedBox(width: 8),
                                Text(
                                  'Start Navigation',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, IconData icon, {bool isStartPoint = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: Icon(icon, color: AppColors.brightCyan),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          if (isStartPoint)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.my_location, color: AppColors.brightCyan),
                onPressed: _isLoading ? null : _useMyLocation,
                tooltip: 'Use my current location',
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceholderMapPage extends StatelessWidget {
  final String startPoint;
  final String destination;
  final Map<String, dynamic> startLocation;
  final Map<String, dynamic> destinationLocation;
  final Map<String, dynamic>? routeData;
  final Map<String, dynamic>? saferRouteData;

  const _PlaceholderMapPage({
    required this.startPoint, 
    required this.destination,
    required this.startLocation,
    required this.destinationLocation,
    this.routeData,
    this.saferRouteData,
  });

  @override
  Widget build(BuildContext context) {
    print('=== PLACEHOLDER MAP PAGE CREATED ===');
    print('Start Point: $startPoint');
    print('Destination: $destination');
    print('Route Data: ${routeData != null ? 'Available' : 'Not available'}');
    print('Safer Route Data: ${saferRouteData != null ? 'Available' : 'Not available'}');
    
    if (routeData != null) {
      print('Route Time: ${routeData!['paths']?[0]?['time']} ms');
      print('Route Distance: ${routeData!['paths']?[0]?['distance']} m');
      final coordinates = routeData!['paths']?[0]?['points']?['coordinates'] as List?;
      print('Route Points: ${coordinates?.length ?? 0}');
    }
    
    if (saferRouteData != null) {
      print('Safer Route Time: ${saferRouteData!['time']} ms');
      print('Safer Route Distance: ${saferRouteData!['distance']} m');
      print('Safer Route Safety Score: ${saferRouteData!['safetyScore']}');
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        backgroundColor: AppColors.deepBlue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RouteSummaryCard(
                startPoint: startPoint,
                destination: destination,
                startLocation: startLocation,
                destinationLocation: destinationLocation,
                routeData: routeData,
              ),
              const SizedBox(height: 24),
              if (routeData != null || saferRouteData != null) ...[
                const Text(
                  'Available Routes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepBlue,
                  ),
                ),
                const SizedBox(height: 16),
                if (routeData != null)
                  WalkingRouteCard(
                    startPoint: startPoint,
                    destination: destination,
                    startLocation: startLocation,
                    destinationLocation: destinationLocation,
                    routeData: routeData!,
                    routeType: 'standard',
                  ),
                if (saferRouteData != null) ...[
                  const SizedBox(height: 16),
                  WalkingRouteCard(
                    startPoint: startPoint,
                    destination: destination,
                    startLocation: startLocation,
                    destinationLocation: destinationLocation,
                    routeData: saferRouteData!,
                    routeType: 'safer',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SafeRoutePage(
                            routeData: saferRouteData!,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}