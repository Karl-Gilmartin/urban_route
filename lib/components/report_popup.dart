import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

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
    final severity = (report['severity'] is int)
        ? (report['severity'] as int).toDouble()
        : (report['severity'] as double? ?? -1.0);
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
                'reports.report_details'.tr(),
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
          _buildInfoRow('reports.report'.tr(), report['report'] ?? 'reports.report_description'.tr()),
          if (report['report_date'] != null)
            _buildInfoRow('reports.date'.tr(), report['report_date']),
          _buildInfoRow(
            'reports.severity'.tr(),
            _getSeverityText(severity),
            valueColor: _getSeverityColor(severity),
          ),
          _buildInfoRow(
            'reports.location'.tr(),
            (report['latitude'] != null && report['longitude'] != null)
                ? '${report['latitude']}, ${report['longitude']}'
                : 'N/A',
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _handleReport(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flag_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  'reports.report_this'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
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
    if (severity == -1) return Colors.grey; // the severity is not set, -1 is the default
    if (severity <= 0.3) return Colors.green;
    if (severity <= 0.7) return Colors.orange;
    return Colors.red;
  }

  String _getSeverityText(double severity) {
    if (severity == -1) return 'reports.not_set'.tr();
    return severity.toStringAsFixed(2);
  }

  void _handleReport(BuildContext context) async {
    final TextEditingController reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('reports.report_this'.tr()),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(labelText: 'reports.reason'.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('reports.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: Text('reports.submit'.tr()),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _submitFlag(result, context);
    }
  }

  Future<void> _submitFlag(String reason, BuildContext context) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('report_flags').insert({
        'report_id': report['id'],
        'flagged_by': user?.id,
        'reason': reason,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('common.success'.tr() + ': ' + 'reports.report_submitted'.tr())),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('common.error'.tr() + ': ' + e.toString())),
      );
    }
  }
} 