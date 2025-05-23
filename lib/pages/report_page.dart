import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:urban_route/main.dart';
import 'package:urban_route/components/status_popup.dart';
import 'package:urban_route/services/supabase_logging.dart';
import 'package:urban_route/schema/database_schema.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController _reportController = TextEditingController();
  String _responseText = '';
  bool _isLoading = false;
  bool _useCurrentLocation = false;
  bool _useAudioInput = false;
  bool _isPublic = false;
  double? _latitude;
  double? _longitude;
  String? _errorMessage;
  int? osmWayId;

  Future<void> _makeHttpRequest() async {
    final inputText = _reportController.text.trim();
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      setState(() {
        _errorMessage = 'Please sign in to submit a report.';
      });
      await SupabaseLogging.logError(
        eventType: '[Report][Report Submit] Authentication required',
        description: 'User attempted to submit report without being signed in',
        error: 'Authentication required',
        statusCode: 401,
      );
      return;
    }

    if (inputText.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a report message.';
      });
      await SupabaseLogging.logError(
        eventType: '[Report][Report Submit] Empty report text',
        description: 'User attempted to submit empty report',
        error: 'Empty report text',
        statusCode: 400,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _responseText = '';
    });

    try {
      // First, send to the emotion analysis server
      final serverResponse = await http.post(
        Uri.parse('http://144.91.67.206:8000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"text": inputText}),
      );

      String emotionResponse = '';
      Map<String, dynamic>? emotionData;
      
      if (serverResponse.statusCode == 200) {
        try {
          final decoded = jsonDecode(serverResponse.body);
          print("About to pring the decoded values");
          print(decoded);
          final List<dynamic> probs = decoded['probabilities'][0];
          const labels = ['Sadness', 'Joy', 'Love', 'Anger', 'Fear', 'Surprise'];
          final predictedLabel = decoded['prediction'] as String;
          emotionResponse = 'Emotion Analysis: $predictedLabel\n\n' +
              List.generate(
                labels.length,
                (i) => '${labels[i]}: ${(probs[i] as num).toStringAsFixed(3)}',
              ).join('\n');
          
          emotionData = {
            'prediction': predictedLabel,
            'probabilities': Map.fromIterables(labels, probs),
          };
          
          await SupabaseLogging.log(
            eventType: 'emotion_analysis',
            description: 'Emotion analysis completed for report',
            metadata: emotionData,
          );
        } catch (e) {
          print('Error parsing emotion response: $e');
          emotionResponse = 'Emotion Analysis: $e';
          
          await SupabaseLogging.logError(
            eventType: '[Report][Emotion Analysis] Error parsing emotion analysis response',
            description: 'Error parsing emotion analysis response',
            error: e.toString(),
            metadata: {'response_body': serverResponse.body},
            statusCode: 500,
          );
        }
      } else {
        await SupabaseLogging.logError(
          eventType: '[Report][Emotion Analysis] Emotion analysis server returned error',
          description: 'Emotion analysis server returned error',
          error: 'HTTP ${serverResponse.statusCode}',
          metadata: {'response_body': serverResponse.body},
          statusCode: 500,
        );
      }
      
      if (_latitude != null && _longitude != null) {
        await _fetchNearestWayId(_latitude!, _longitude!);
      }

      // Then, save to Supabase (normalized schema)
      // 1. Insert location
      final locationInsert = await Supabase.instance.client
          .from(DatabaseSchema.reportLocations)
          .insert(DatabaseSchema.createReportLocationRecord(
            latitude: _latitude ?? -1,
            longitude: _longitude ?? -1,
            address: '', // Optionally add address lookup
            osmId: osmWayId?.toString() ?? '-1',
          ))
          .select('id')
          .single();
      final locationId = locationInsert['id'];

      // 2. Insert report
      final reportInsert = await Supabase.instance.client
          .from(DatabaseSchema.reports)
          .insert(DatabaseSchema.createReportRecord(
            userId: currentUser.id,
            severity: -1,
            status: -1,
            isPublic: _isPublic,
            osmWayId: osmWayId?.toString() ?? '-1',
            locationId: locationId,
          ))
          .select('id')
          .single();
      final reportId = reportInsert['id'];

      // 3. Insert report content
      await Supabase.instance.client
          .from(DatabaseSchema.reportContents)
          .insert(DatabaseSchema.createReportContentRecord(
            reportId: reportId,
            language: 'en',
            reportText: inputText,
            audioUrl: null,
            mediaUrls: null,
          ));

      print('Report submitted with reportId: $reportId'); // Debug print
      
      // Log successful report submission
      await SupabaseLogging.log(
        eventType: '[Report][Report Submit] Successful report submission',
        description: 'User submitted a new report',
        metadata: {
          'report_id': reportId,
          'is_public': _isPublic,
          'has_location': _latitude != null && _longitude != null,
          'osm_way_id': osmWayId,
          'emotion_analysis': emotionData,
        },
      );

      setState(() {
        _responseText = 'Report submitted successfully!\n\n$emotionResponse';
        // Clear the form after successful submission
        _reportController.clear();
        _latitude = null;
        _longitude = null;
        _useCurrentLocation = false;
      });
      
      if (mounted) {
        StatusPopup.showSuccess(
          context: context,
          message: 'Your report has been submitted successfully.',
          buttonText: 'Done',
          onButtonPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        );
      }
    } catch (e, stackTrace) {
      print('Error submitting report: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Error: $e';
      });
      
      await SupabaseLogging.logError(
        eventType: '[Report][Report Submit] Error submitting report',
        description: 'Error submitting report',
        error: e.toString(),
        metadata: {
          'stack_trace': stackTrace.toString(),
          'report_text_length': inputText.length,
          'has_location': _latitude != null && _longitude != null,
        },
        statusCode: 500,
      );
      
      if (mounted) {
        StatusPopup.showError(
          context: context,
          message: 'Failed to submit report: $e',
          onButtonPressed: () => Navigator.of(context).pop(),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNearestWayId(double latitude, double longitude) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1');

      final response = await http.get(url, headers: {
        'User-Agent': 'urban_route_app/1.0 (your@email.com)',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('osm_type') && data.containsKey('osm_id')) {
          osmWayId = data['osm_id'];
          print('OSM ID (closest way/node): ${data['osm_id']}');
          
          await SupabaseLogging.log(
            eventType: '[Report][OSM Lookup] Successful OSM way ID lookup',
            description: 'OSM way ID lookup successful',
            metadata: {
              'osm_id': data['osm_id'],
              'osm_type': data['osm_type'],
              'latitude': latitude,
              'longitude': longitude,
            },
          );
        } else {
          print('No OSM ID found for this location, falling back to -1 as failsafe.');
          osmWayId = -1;
          
          await SupabaseLogging.logError(
            eventType: '[Report][OSM Lookup] No OSM ID found for location',
            description: 'No OSM ID found for location',
            error: 'Missing OSM data',
            metadata: {
              'latitude': latitude,
              'longitude': longitude,
              'response': data,
            },
            statusCode: 500,
          );
        }
      } else {
        print('Error fetching OSM data, using -1 as failsafe: ${response.statusCode}');
        osmWayId = -1;
        
        await SupabaseLogging.logError(
          eventType: '[Report][OSM Lookup] OSM API request failed',
          description: 'OSM API request failed',
          error: 'HTTP ${response.statusCode}',
          metadata: {
            'latitude': latitude,
            'longitude': longitude,
            'response_body': response.body,
          },
          statusCode: 500,
        );
      }
    } catch (e) {
      print('Error during OSM reverse lookup, using -1 as failsafe: $e');
      osmWayId = -1;
      
      await SupabaseLogging.logError(
        eventType: '[Report][OSM Lookup] Error during OSM reverse lookup',
        description: 'Error during OSM reverse lookup',
        error: e.toString(),
        metadata: {
          'latitude': latitude,
          'longitude': longitude,
        },
        statusCode: 500,
      );
    }
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.deepBlue,
              AppColors.brightCyan.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button and title
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Create Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Location Section
                            const Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepBlue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Switch(
                                  value: _useCurrentLocation,
                                  activeColor: AppColors.brightCyan,
                                  onChanged: (value) async {
                                    setState(() => _useCurrentLocation = value);
                                    if (value) {
                                      try {
                                        final position = await Geolocator.getCurrentPosition(
                                          desiredAccuracy: LocationAccuracy.high,
                                        );
                                        setState(() {
                                          _latitude = position.latitude;
                                          _longitude = position.longitude;
                                        });
                                      } catch (e) {
                                        print('Error getting location: $e');
                                        setState(() {
                                          _errorMessage = 'Error getting location: $e';
                                        });
                                        
                                        await SupabaseLogging.logError(
                                          eventType: '[Report][Location Error] Error getting user location',
                                          description: 'Error getting user location',
                                          error: e.toString(),
                                          statusCode: 500,
                                        );
                                      }
                                    } else {
                                      setState(() {
                                        _latitude = null;
                                        _longitude = null;
                                      });
                                      
                                      await SupabaseLogging.log(
                                        eventType: '[Report][Location Error] User disabled location for report',
                                        description: 'User disabled location for report',
                                      );
                                    }
                                  },
                                ),
                                const Text('Use Current Location'),
                              ],
                            ),
                            if (_useCurrentLocation && _latitude != null && _longitude != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Location: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                  style: const TextStyle(color: AppColors.brightCyan),
                                ),
                              ),
                            const SizedBox(height: 24),

                            // Public/Private Toggle
                            const Text(
                              'Report Visibility',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepBlue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ToggleButtons(
                                  isSelected: [!_isPublic, _isPublic],
                                  onPressed: (index) {
                                    setState(() {
                                      _isPublic = index == 1;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  selectedColor: Colors.white,
                                  fillColor: AppColors.brightCyan,
                                  color: Colors.grey[700],
                                  constraints: const BoxConstraints(
                                    minWidth: 100,
                                    minHeight: 40,
                                  ),
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.lock_outline, size: 18),
                                          SizedBox(width: 8),
                                          Text('Private'),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.public_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Public'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                const Tooltip(
                                  message: 'Public reports can be viewed by other users',
                                  child: Icon(Icons.info_outline, size: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Input Method Selection
                            const Text(
                              'Input Method',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepBlue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _useAudioInput = true),
                                    child: Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: _useAudioInput ? AppColors.brightCyan.withOpacity(0.2) : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _useAudioInput ? AppColors.brightCyan : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.mic,
                                              color: _useAudioInput ? AppColors.brightCyan : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Audio Input',
                                              style: TextStyle(
                                                color: _useAudioInput ? AppColors.brightCyan : Colors.grey[600],
                                                fontWeight: _useAudioInput ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _useAudioInput = false),
                                    child: Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: !_useAudioInput ? AppColors.brightCyan.withOpacity(0.2) : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: !_useAudioInput ? AppColors.brightCyan : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.edit,
                                              color: !_useAudioInput ? AppColors.brightCyan : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Text Input',
                                              style: TextStyle(
                                                color: !_useAudioInput ? AppColors.brightCyan : Colors.grey[600],
                                                fontWeight: !_useAudioInput ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Dictation or Text Input
                            if (_useAudioInput) ...[
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: null, // Hook up mic logic here
                                  icon: const Icon(Icons.mic),
                                  label: const Text('Start Dictation'),
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStatePropertyAll(AppColors.brightCyan),
                                    foregroundColor: MaterialStatePropertyAll(Colors.white),
                                    padding: MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
                                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(12)),
                                    )),
                                  ),
                                ),
                              ),
                            ] else ...[
                              const Text(
                                'Report Message',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepBlue,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _reportController,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  hintText: 'Describe your issue here...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.brightCyan, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                  fillColor: Colors.grey[50],
                                  filled: true,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _makeHttpRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brightCyan,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Submit Report',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ],

                            // Error message
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],

                            // Response
                            if (_responseText.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[50],
                                ),
                                child: Text(
                                  _responseText,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
