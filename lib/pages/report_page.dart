import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  String _locationText = 'Location not available';
  bool _isLoadingLocation = false;

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationText = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = 'Location permissions are permanently denied';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _locationText = 'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationText = 'Error getting location: $e';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _makeHttpRequest() async {
    final inputText = _reportController.text.trim();

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
      final response = await http.post(
        Uri.parse('http://144.91.67.206:8000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"text": inputText}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final int prediction = decoded['prediction'];
        final List<dynamic> probs = decoded['probabilities'][0];

        const labels = ['Sadness', 'Joy', 'Love', 'Anger', 'Fear', 'Surprise'];
        final predictedLabel = labels[prediction];

        setState(() {
          _responseText =
              'Prediction: $predictedLabel\n\n' +
              List.generate(
                labels.length,
                (i) => '${labels[i]}: ${probs[i].toStringAsFixed(3)}',
              ).join('\n');
        });
      } else {
        setState(() {
          _responseText = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
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
                  onChanged: (value) {
                    setState(() {
                      _useCurrentLocation = value;
                      if (value) {
                        _getCurrentLocation();
                      }
                    });
                  },
                ),
                const Text('My Current Location'),
              ],
            ),
            if (_useCurrentLocation) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Row(
                  children: [
                    if (_isLoadingLocation)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1F8DED)),
                        ),
                      )
                    else
                      const Icon(Icons.location_on, color: Color(0xFF1F8DED)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationText,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
