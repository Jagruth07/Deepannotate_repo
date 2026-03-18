import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../main.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  // Create Task form controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isCreating = false;

  // Submissions state
  List<dynamic> _submissions = [];
  bool _isLoadingSubmissions = true;
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
    _connectSocket();
  }

  void _connectSocket() {
    socket = IO.io(Constants.backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.on('new_submission', (data) {
      print('New real-time submission received: $data');
      if (mounted) {
        setState(() {
          _submissions.insert(0, data); // Add to top of list
        });
      }
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoadingSubmissions = true);
    try {
      final subs = await ApiService.fetchSubmissions();
      if (mounted) {
        setState(() {
          _submissions = subs;
        });
      }
    } catch (e) {
      print('Failed to load submissions: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingSubmissions = false);
      }
    }
  }

  Future<void> _submitTask() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    
    setState(() => _isCreating = true);
    
    final success = await ApiService.createTask(
      _titleController.text,
      _descController.text,
    );
    
    setState(() => _isCreating = false);
    
    if (success) {
      _titleController.clear();
      _descController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task Published Successfully!'), backgroundColor: Colors.green),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to publish task'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildCreateTaskTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Publish a new capture task for users.', 
            style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Task Title',
              hintText: 'e.g. Record 5 seconds of street noise',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Detailed Instructions',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isCreating ? null : _submitTask,
              child: _isCreating 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Publish Task', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsTab() {
    if (_isLoadingSubmissions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_submissions.isEmpty) {
      return const Center(
        child: Text('No submissions yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubmissions,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _submissions.length,
        itemBuilder: (context, index) {
          final sub = _submissions[index];
          final date = DateTime.tryParse(sub['created_at'].toString())?.toLocal().toString() ?? 'Unknown date';
          
          return Card(
            child: ListTile(
              leading: const Icon(Icons.file_present),
              title: Text(sub['task_title'] ?? 'Unknown Task'),
              subtitle: Text(date.split('.')[0]),
              trailing: IconButton(
                icon: const Icon(Icons.link, color: Colors.blue),
                onPressed: () {
                  // Print URL or try to launch URL
                  print(sub['file_url']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('File URL: \n${sub['file_url']}')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Create Task' : 'Live Submissions'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (_, mode, __) {
              return IconButton(
                icon: Icon(mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode),
                onPressed: () {
                  themeNotifier.value = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (_) => const LoginScreen())
              );
            },
          )
        ],
      ),
      body: _currentIndex == 0 ? _buildCreateTaskTab() : _buildSubmissionsTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_task),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Submissions',
          ),
        ],
      ),
    );
  }
}
