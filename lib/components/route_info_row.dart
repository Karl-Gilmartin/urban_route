import 'package:flutter/material.dart';
import 'package:urban_route/main.dart';

class RouteInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const RouteInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.deepBlue,
            ),
          ),
        ],
      ),
    );
  }
} 