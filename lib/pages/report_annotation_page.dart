import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_route/main.dart';
import 'package:urban_route/components/status_popup.dart';
import 'package:urban_route/services/supabase_logging.dart';
import 'package:urban_route/schema/database_schema.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:urban_route/components/report_annotation_card.dart';

class ReportAnnotationPage extends StatefulWidget {
  const ReportAnnotationPage({super.key});

  @override
  State<ReportAnnotationPage> createState() => _ReportAnnotationPageState();
}

class _ReportAnnotationPageState extends State<ReportAnnotationPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Join reports with report_contents to get the text
      final response = await _supabase
          .from(DatabaseSchema.reports)
          .select('''
            ${Reports.id},
            ${Reports.userId},
            ${Reports.severity},
            ${Reports.status},
            ${Reports.isPublic},
            ${Reports.osmWayId},
            ${Reports.locationId},
            ${Reports.submittedAt},
            report_contents!report_contents_report_id_fkey (
              ${ReportContents.reportText},
              ${ReportContents.language}
            )
          ''')
          .order(Reports.submittedAt, ascending: false);

      setState(() {
        _reports = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
      
      await SupabaseLogging.log(
        eventType: '[Report][Annotation] Reports loaded',
        description: 'Reports loaded for annotation',
        metadata: {'count': _reports.length},
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading reports: $e';
        _isLoading = false;
      });
      
      await SupabaseLogging.logError(
        eventType: '[Report][Annotation] Error loading reports',
        description: 'Error loading reports for annotation',
        error: e.toString(),
        statusCode: 500,
      );
    }
  }

  Future<void> _submitAnnotation(int reportId, double severity) async {
    // Check if user is authenticated
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        StatusPopup.showError(
          context: context,
          message: 'You must be logged in to annotate reports.',
          buttonText: 'OK',
          onButtonPressed: () {
            Navigator.of(context).pop();
          },
        );
      }
      
      await SupabaseLogging.logError(
        eventType: '[Report][Annotation] Authentication required',
        description: 'User attempted to annotate without being logged in',
        error: 'Authentication required',
        statusCode: 401,
      );
      return;
    }

    try {
      // Log the current user for debugging
      print('Current user ID: ${user.id}');
      
      // First, try to update the severity in the reports table
      final updateResult = await _supabase
          .from(DatabaseSchema.reports)
          .update({Reports.severity: severity})
          .eq(Reports.id, reportId);
      
      print('Reports update success');
      
      // Create data using the schema helper
      final data = DatabaseSchema.createReportsTrainableRecord(
        reportId: reportId,
        severity: severity.round(),
      );
      
      // Log the data being inserted for debugging
      print('Inserting data: $data');
      
      // Try to upsert into reports_trainable table
      try {
        final result = await _supabase
            .from(DatabaseSchema.reportsTrainable)
            .upsert(data);
        
        print('Upsert successful');
        
        // Show success message
        if (mounted) {
          StatusPopup.showSuccess(
            context: context,
            message: 'Report annotation saved successfully.',
            buttonText: 'OK',
            onButtonPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          );
        }
        
        await SupabaseLogging.log(
          eventType: '[Report][Annotation] Report annotated',
          description: 'Report annotated with severity score',
          metadata: {
            'report_id': reportId,
            'severity': severity,
            'user_id': user.id,
          },
        );
      } catch (e) {
        print('Upsert error: $e');
        // Try insert as fallback
        try {
          final insertResult = await _supabase
              .from(DatabaseSchema.reportsTrainable)
              .insert(data);
          print('Insert successful as fallback');
        } catch (insertError) {
          print('Insert error: $insertError');
          throw insertError; // Rethrow to be caught by outer catch
        }
      }
      
      // Refresh the list
      _loadReports();
    } catch (e) {
      final errorMessage = 'Error saving annotation: $e';
      print(errorMessage);
      
      setState(() {
        _errorMessage = errorMessage;
      });
      
      await SupabaseLogging.logError(
        eventType: '[Report][Annotation] Error saving annotation',
        description: 'Error saving report annotation',
        error: e.toString(),
        statusCode: 500,
      );
      
      // Show error message
      if (mounted) {
        StatusPopup.showError(
          context: context,
          message: errorMessage,
          buttonText: 'OK',
          onButtonPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Annotation'.tr()),
        backgroundColor: AppColors.deepBlue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
              : _reports.isEmpty
                  ? Center(child: Text('No reports available for annotation.'.tr()))
                  : ListView.builder(
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        return ReportAnnotationCard(
                          report: _reports[index],
                          onSubmitAnnotation: _submitAnnotation,
                        );
                      },
                    ),
    );
  }
} 