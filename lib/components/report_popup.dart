import 'package:flutter/material.dart';

class ReportPopup extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback? onClose;

  const ReportPopup({
    super.key,
    required this.report,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Report Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Report', report['report'] ?? 'No description'),
          _buildInfoRow('Date', report['report_date'] ?? 'N/A'),
          _buildInfoRow(
            'Severity',
            '${(report['severity'] ?? 0).toStringAsFixed(2)}',
            valueColor: _getSeverityColor(report['severity'] ?? 0),
          ),
          _buildInfoRow(
            'Location',
            '${report['latitude']}, ${report['longitude']}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(double severity) {
    if (severity <= 0.3) return Colors.green;
    if (severity <= 0.7) return Colors.orange;
    return Colors.red;
  }
} 