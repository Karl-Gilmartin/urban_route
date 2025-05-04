import 'package:flutter/material.dart';
import 'package:urban_route/main.dart';
import 'route_info_row.dart';
import '../pages/route_page.dart';
import '../pages/safe_route_page.dart';

class WalkingRouteCard extends StatelessWidget {
  final String startPoint;
  final String destination;
  final Map<String, dynamic> startLocation;
  final Map<String, dynamic> destinationLocation;
  final Map<String, dynamic> routeData;
  final String routeType; // 'standard' or 'safer'
  final VoidCallback? onTap;

  const WalkingRouteCard({
    super.key,
    required this.startPoint,
    required this.destination,
    required this.startLocation,
    required this.destinationLocation,
    required this.routeData,
    this.routeType = 'standard',
    this.onTap,
  });

  String _formatDuration(int milliseconds) {
    if (milliseconds == null || milliseconds <= 0) {
      return 'No time available';
    }
    
    final minutes = (milliseconds / 60000).round();
    if (minutes < 60) {
      return '$minutes minutes';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours hour${hours > 1 ? 's' : ''} $remainingMinutes minute${remainingMinutes != 1 ? 's' : ''}';
    }
  }

  String _formatDistance(double meters) {
    if (meters == null || meters <= 0) {
      return 'No distance available';
    }
    
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSaferRoute = routeType == 'safer';
    final int time = isSaferRoute 
        ? (routeData['time'] ?? 0) 
        : (routeData['paths']?[0]?['time'] ?? 0);
    final double distance = isSaferRoute 
        ? (routeData['distance'] ?? 0.0) 
        : (routeData['paths']?[0]?['distance'] ?? 0.0);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap ?? () {
          if (isSaferRoute) {
            print('Navigating to SafeRoutePage with data: $routeData');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SafeRoutePage(
                  routeData: routeData,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoutePage(
                  startLocation: startLocation,
                  destinationLocation: destinationLocation,
                  routeData: routeData,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brightCyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_walk, 
                          color: AppColors.brightCyan,
                          size: 24,
                        ),
                        if (isSaferRoute) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.shield,
                            color: AppColors.deepBlue.withOpacity(0.6),
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isSaferRoute ? 'Safer Walking Route' : 'Walking Route',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: AppColors.brightCyan),
                ],
              ),
              const SizedBox(height: 8),
              RouteInfoRow(
                label: 'Time',
                value: _formatDuration(time),
              ),
              RouteInfoRow(
                label: 'Distance',
                value: _formatDistance(distance),
              ),
              if (isSaferRoute) ...[
                const SizedBox(height: 8),
                const Text(
                  'This route prioritizes safety over speed, avoiding areas with may be deemed unsafe.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 