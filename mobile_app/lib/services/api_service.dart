import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class ApiService {
  static Future<List<dynamic>> fetchTasks() async {
    try {
      final response = await http.get(Uri.parse('${Constants.backendUrl}/tasks'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      // Return empty list or throw depending on requirements
      print('Error fetching tasks: $e');
      throw Exception('Network error or server down : $e');
    }
  }

  static Future<bool> submitTaskCompletion(String taskId, String fileUrl) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.backendUrl}/submission'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'task_id': taskId,
          'file_url': fileUrl,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error submitting completion: $e');
      return false;
    }
  }

  static Future<bool> createTask(String title, String description) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.backendUrl}/task'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'title': title, 'description': description}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error creating task: $e');
      return false;
    }
  }

  static Future<List<dynamic>> fetchSubmissions() async {
    try {
      final response = await http.get(Uri.parse('${Constants.backendUrl}/submissions'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load submissions');
      }
    } catch (e) {
      print('Error fetching submissions: $e');
      throw Exception('Network error: $e');
    }
  }
}
