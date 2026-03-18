import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadStatusScreen extends StatefulWidget {
  final String taskId;
  final String filePath;
  final String fileName;

  const UploadStatusScreen({
    super.key,
    required this.taskId,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<UploadStatusScreen> createState() => _UploadStatusScreenState();
}

class _UploadStatusScreenState extends State<UploadStatusScreen> {
  String _statusMessage = 'Uploading to Cloud...';
  bool _isUploading = true;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _startUpload();
  }

  Future<void> _startUpload() async {
    try {
      final file = File(widget.filePath);
      final sanitizedFileName = widget.fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';

      // 1. Get Pre-signed URL from Backend
      final urlRes = await http.get(Uri.parse('${Constants.backendUrl}/s3-upload-url?fileName=$uniqueFileName&fileType=application/octet-stream'));
      if (urlRes.statusCode != 200) throw Exception('Failed to get upload URL');
      final urlData = json.decode(urlRes.body);
      final uploadUrl = urlData['uploadUrl'];
      final publicUrl = urlData['publicUrl'];

      // 2. Upload to S3 directly via HTTP PUT
      final fileBytes = await file.readAsBytes();
      final uploadRes = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': 'application/octet-stream'},
        body: fileBytes,
      );

      if (uploadRes.statusCode != 200) throw Exception('Failed to upload file to S3');

      setState(() {
        _statusMessage = 'Finalizing Submission...';
      });

      // 3. Send Task ID and Public S3 File URL to Node.js Backend API
      final success = await ApiService.submitTaskCompletion(widget.taskId, publicUrl);

      if (success) {
        // Save to local completed list
        final prefs = await SharedPreferences.getInstance();
        final completedLists = prefs.getStringList('completed_tasks') ?? [];
        if (!completedLists.contains(widget.taskId)) {
          completedLists.add(widget.taskId);
          await prefs.setStringList('completed_tasks', completedLists);
        }

        setState(() {
          _statusMessage = 'Upload Complete! Submission Sent.';
          _isUploading = false;
          _isSuccess = true;
        });
      } else {
        throw Exception('Failed to record submission in backend API');
      }
    } catch (e) {
      print('Upload error: $e');
      setState(() {
        _statusMessage = 'Error occurred during upload: $e';
        _isUploading = false;
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Status')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isUploading)
                const CircularProgressIndicator()
              else if (_isSuccess)
                const Icon(Icons.check_circle, color: Colors.green, size: 80)
              else
                 const Icon(Icons.error, color: Colors.red, size: 80),
                 
              const SizedBox(height: 24),
              
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isSuccess ? Colors.green : (_isUploading ? Colors.black : Colors.red),
                ),
              ),
              
              const SizedBox(height: 40),
              if (!_isUploading)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Back to Tasks'),
                )
            ],
          ),
        ),
      ),
    );
  }
}
