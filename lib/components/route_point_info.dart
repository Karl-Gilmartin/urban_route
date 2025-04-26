import 'package:flutter/material.dart';
import 'package:urban_route/main.dart';

class RoutePointInfo extends StatelessWidget {
  final String label;
  final String address;
  final Map<String, dynamic> location;

  const RoutePointInfo({
    super.key,
    required this.label,
    required this.address,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.brightCyan,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          address,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          '${location['latitude']}, ${location['longitude']}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
} 