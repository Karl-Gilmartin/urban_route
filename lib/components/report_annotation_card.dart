import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:urban_route/main.dart';
import 'package:urban_route/schema/database_schema.dart';

class ReportAnnotationCard extends StatefulWidget {
  final Map<String, dynamic> report;
  final Function(int reportId, double severity) onSubmitAnnotation;

  const ReportAnnotationCard({
    Key? key,
    required this.report,
    required this.onSubmitAnnotation,
  }) : super(key: key);

  @override
  State<ReportAnnotationCard> createState() => _ReportAnnotationCardState();
}

class _ReportAnnotationCardState extends State<ReportAnnotationCard> {
  late double currentSeverity;

  @override
  void initState() {
    super.initState();

    final reportSeverity = widget.report[Reports.severity];
    currentSeverity = reportSeverity is! double || reportSeverity < 0 
        ? 0.0 
        : reportSeverity;
  }

  @override
  Widget build(BuildContext context) {
    final reportId = widget.report[Reports.id]?.toString() ?? 'Unknown';
    final submittedAt = widget.report[Reports.submittedAt] != null 
        ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(widget.report[Reports.submittedAt]))
        : 'Unknown date';
        
    String reportText = 'No content'.tr();
    try {
      if (widget.report['report_contents'] != null) {
        final reportContents = List<Map<String, dynamic>>.from(widget.report['report_contents']);
        if (reportContents.isNotEmpty && reportContents[0][ReportContents.reportText] != null) {
          reportText = reportContents[0][ReportContents.reportText];
        }
      }
    } catch (e) {
      print('Error extracting report text: $e');
      reportText = 'Error loading content'.tr();
    }
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report #$reportId'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Submitted: $submittedAt'.tr()),
            const SizedBox(height: 16),
            Text(
              'Report Content:'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(reportText),
            ),
            const SizedBox(height: 16),
            Text(
              'Severity Rating (0-5):'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: currentSeverity,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: currentSeverity.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        currentSeverity = value;
                      });
                    },
                  ),
                ),
                Text(currentSeverity.round().toString()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    int id = -1;
                    try {
                      id = int.parse(reportId.toString());
                      widget.onSubmitAnnotation(id, currentSeverity);
                    } catch (e) {
                      print('Error parsing report ID: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyanBlue,
                  ),
                  child: Text('Save Annotation'.tr(), style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 