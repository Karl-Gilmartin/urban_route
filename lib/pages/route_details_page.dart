import 'package:flutter/material.dart';
import 'package:urban_route/main.dart';
import '../components/route_point_info.dart';
import '../components/route_info_row.dart';

class RouteDetailsPage extends StatelessWidget {
  final String startPoint;
  final String destination;
  final Map<String, dynamic> startLocation;
  final Map<String, dynamic> destinationLocation;
  final Map<String, dynamic> routeData;

  const RouteDetailsPage({
    super.key,
    required this.startPoint,
    required this.destination,
    required this.startLocation,
    required this.destinationLocation,
    required this.routeData,
  });

  @override
  Widget build(BuildContext context) {
    final coordinates = routeData['paths']?[0]?['points']?['coordinates'] as List?;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
        backgroundColor: AppColors.deepBlue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Route Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RoutePointInfo(
                        label: 'Start',
                        address: startPoint,
                        location: startLocation,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Icon(Icons.arrow_downward, color: AppColors.brightCyan),
                      ),
                      RoutePointInfo(
                        label: 'Destination',
                        address: destination,
                        location: destinationLocation,
                      ),
                      const Divider(height: 32),
                      RouteInfoRow(
                        label: 'Estimated Time',
                        value: '${(routeData['paths']?[0]?['time'] ?? 0) ~/ 60000} minutes',
                      ),
                      RouteInfoRow(
                        label: 'Distance',
                        value: '${((routeData['paths']?[0]?['distance'] ?? 0) / 1000).toStringAsFixed(1)} km',
                      ),
                      RouteInfoRow(
                        label: 'Ascent',
                        value: '${(routeData['paths']?[0]?['ascend'] ?? 0).toStringAsFixed(1)} m',
                      ),
                      RouteInfoRow(
                        label: 'Descent',
                        value: '${(routeData['paths']?[0]?['descend'] ?? 0).toStringAsFixed(1)} m',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement navigation start
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brightCyan,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Row(
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
    );
  }
} 