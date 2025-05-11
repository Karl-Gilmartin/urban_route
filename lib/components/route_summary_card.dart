import 'package:flutter/material.dart';
import 'package:urban_route/main.dart';
import 'package:easy_localization/easy_localization.dart';
import 'route_info_row.dart';
import 'route_point_info.dart';

class RouteSummaryCard extends StatelessWidget {
  final String startPoint;
  final String destination;
  final Map<String, dynamic> startLocation;
  final Map<String, dynamic> destinationLocation;
  final Map<String, dynamic>? routeData;

  const RouteSummaryCard({
    super.key,
    required this.startPoint,
    required this.destination,
    required this.startLocation,
    required this.destinationLocation,
    this.routeData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'components.route_summary_card.route_summary'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.deepBlue,
              ),
            ),
            const SizedBox(height: 16),
            RoutePointInfo(
              label: 'components.route_summary_card.start'.tr(),
              address: startPoint,
              location: startLocation,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Icon(Icons.arrow_downward, color: AppColors.brightCyan),
            ),
            RoutePointInfo(
              label: 'components.route_summary_card.destination'.tr(),
              address: destination,
              location: destinationLocation,
            ),
          ],
        ),
      ),
    );
  }
} 