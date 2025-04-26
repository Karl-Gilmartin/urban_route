import 'package:flutter/material.dart';
import 'package:urban_route/main.dart';
import 'route_info_row.dart';
import '../pages/route_details_page.dart';

class WalkingRouteCard extends StatelessWidget {
  final String startPoint;
  final String destination;
  final Map<String, dynamic> startLocation;
  final Map<String, dynamic> destinationLocation;
  final Map<String, dynamic> routeData;

  const WalkingRouteCard({
    super.key,
    required this.startPoint,
    required this.destination,
    required this.startLocation,
    required this.destinationLocation,
    required this.routeData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RouteDetailsPage(
                startPoint: startPoint,
                destination: destination,
                startLocation: startLocation,
                destinationLocation: destinationLocation,
                routeData: routeData,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_walk, color: AppColors.brightCyan),
                  const SizedBox(width: 8),
                  const Text(
                    'Walking Route',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, color: AppColors.brightCyan),
                ],
              ),
              const SizedBox(height: 8),
              RouteInfoRow(
                label: 'Time',
                value: '${(routeData['paths']?[0]?['time'] ?? 0) ~/ 60000} minutes',
              ),
              RouteInfoRow(
                label: 'Distance',
                value: '${((routeData['paths']?[0]?['distance'] ?? 0) / 1000).toStringAsFixed(1)} km',
              ),
            ],
          ),
        ),
      ),
    );
  }
} 