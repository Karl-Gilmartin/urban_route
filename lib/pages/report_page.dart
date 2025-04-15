import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

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
  int? _latitude;
  int? _longitude;

  Future<void> _makeHttpRequest() async {
    final inputText = _reportController.text.trim();
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      setState(() {
        _responseText = 'Please sign in to submit a report.';
      });
      return;
    }

    if (inputText.isEmpty) {
      setState(() {
        _responseText = 'Please enter a report message.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
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
        } catch (e) {
          print('Error parsing emotion response: $e');
          emotionResponse = 'Emotion Analysis: $e';
        }
      }

      // Prepare the report data with explicit typing
      final reportData = {
        'user_id': currentUser.id,
        'report_date': DateTime.now().toIso8601String(),
        'severity': -1,
        'report_en': inputText,
        'report': inputText,
        'audio_url': null,
        'longitude': _longitude != null ? _longitude as int : -1,
        'latitude': _latitude != null ? _latitude as int : -1,
        'status': -1,
        'media_url': null,
        'is_public': _isPublic,
      };

      print('Submitting report with data: $reportData'); // Debug print

      // Then, save to Supabase
      final response = await Supabase.instance.client
          .from('reports')
          .insert(reportData)
          .select();

      print('Supabase response: $response'); // Debug print

      setState(() {
        _responseText = 'Report submitted successfully!\n\n$emotionResponse';
        // Clear the form after successful submission
        _reportController.clear();
        _latitude = null;
        _longitude = null;
        _useCurrentLocation = false;
      });
    } catch (e, stackTrace) {
      print('Error submitting report: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _responseText = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      appBar: AppBar(
        title: const Text('Report'),
        backgroundColor: const Color(0xFF1F8DED),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please fill out the following information to make a report',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Location Section
            const Text('Location:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Please enter your location or allow your current location'),
            Row(
              children: [
                Switch(
                  value: _useCurrentLocation,
                  onChanged: (value) async {
                    setState(() => _useCurrentLocation = value);
                    if (value) {
                      try {
                        final position = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high,
                        );
                        setState(() {
                          // Convert to integers by multiplying by 1e6 and rounding
                          _latitude = (position.latitude * 1e6).round();
                          _longitude = (position.longitude * 1e6).round();
                        });
                      } catch (e) {
                        print('Error getting location: $e');
                      }
                    } else {
                      setState(() {
                        _latitude = null;
                        _longitude = null;
                      });
                    }
                  },
                ),
                const Text('My Current Location'),
              ],
            ),
            if (_useCurrentLocation && _latitude != null && _longitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Location: ${(_latitude! / 1e6).toStringAsFixed(6)}, ${(_longitude! / 1e6).toStringAsFixed(6)}',
                  style: const TextStyle(color: Color(0xFF1F8DED)),
                ),
              ),
            const SizedBox(height: 20),

            // Public/Private Toggle
            const Text('Report Visibility:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
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
                  fillColor: const Color(0xFF1F8DED),
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
            const SizedBox(height: 20),

            // Input Method Selection
            const Text('How would you like to make your report?'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _useAudioInput = true),
                    child: Container(
                      height: 60,
                      color: _useAudioInput ? Colors.grey[400] : Colors.grey[200],
                      child: const Center(child: Text('Audio Input')),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _useAudioInput = false),
                    child: Container(
                      height: 60,
                      color: !_useAudioInput ? Colors.grey[400] : Colors.grey[200],
                      child: const Center(child: Text('Text Input')),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Dictation or Text Input
            if (_useAudioInput) ...[
              const Center(
                child: ElevatedButton(
                  onPressed: null, // Hook up mic logic here
                  child: Text('🎙️ Start Dictation'),
                ),
              ),
            ] else ...[
              const Text('Please enter your report message:'),
              const SizedBox(height: 8),
              TextField(
                controller: _reportController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Describe your issue here...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _makeHttpRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F8DED),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Submit Report', style: TextStyle(color: Colors.white)),
              ),
            ],

            // Response
            if (_responseText.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
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
    );
  }
}
