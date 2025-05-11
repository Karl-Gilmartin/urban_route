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
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.92),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 12.0),
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.cyanBlue, AppColors.brightCyan],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.assignment,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report #$reportId'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Submitted: $submittedAt'.tr(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Report content section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.message, color: AppColors.deepBlue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Report Content:'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: AppColors.deepBlue,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        reportText,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Severity rating section
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: AppColors.deepBlue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Severity Rating:'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepBlue,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.brightCyan,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${currentSeverity.round()}/5',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.brightCyan,
                        inactiveTrackColor: Colors.grey[300],
                        thumbColor: AppColors.brightCyan,
                        overlayColor: AppColors.brightCyan.withOpacity(0.2),
                        valueIndicatorColor: AppColors.deepBlue,
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                    
                    const SizedBox(height: 20),
                    
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
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
                          backgroundColor: AppColors.brightCyan,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Save Annotation'.tr(), 
                              style: TextStyle(
                                color: Colors.white, 
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 