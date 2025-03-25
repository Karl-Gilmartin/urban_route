import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController _reportController = TextEditingController();
  String _responseText = '';
  bool _isLoading = false;

  Future<void> _makeHttpRequest() async {
  final inputText = _reportController.text.trim();

  if (inputText.isEmpty) {
    setState(() {
      _responseText = 'Please enter some text to analyze.';
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
      setState(() {
        _responseText = 'Prediction: ${decoded['prediction']}, values: ${decoded['probabilities']}';
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Report an Issue',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
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
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Make HTTP Request',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
          ),
          if (_responseText.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Response:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _responseText,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
