import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'task_detail_screen.dart';
import 'login_screen.dart';
import '../main.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> _tasksFuture;
  late TabController _tabController;
  Set<String> _completedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCompletedTasks();
    _tasksFuture = ApiService.fetchTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCompletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _completedTaskIds = (prefs.getStringList('completed_tasks') ?? []).toSet();
    });
  }

  Future<void> _refresh() async {
    await _loadCompletedTasks();
    setState(() {
      _tasksFuture = ApiService.fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DeepAnnotate Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
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
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'AVAILABLE'),
            Tab(text: 'COMPLETED'),
          ],
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
             return Center(
               child: Padding(
                 padding: const EdgeInsets.all(20.0),
                 child: Text('Error: ${snapshot.error}\nMake sure your backend is running!', textAlign: TextAlign.center),
               ),
             );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
             return const Center(child: Text('No tasks created yet.'));
          }

          final allTasks = snapshot.data!;
          final availableTasks = allTasks.where((task) => !_completedTaskIds.contains(task['id'].toString())).toList();
          final completedTasks = allTasks.where((task) => _completedTaskIds.contains(task['id'].toString())).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(availableTasks, false),
              _buildTaskList(completedTasks, true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskList(List<dynamic> tasks, bool isCompletedList) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isCompletedList ? Icons.done_all : Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isCompletedList ? 'No completed tasks yet.' : 'You are all caught up!',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isCompletedList ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailScreen(
                      taskId: task['id'].toString(),
                      title: task['title'] ?? '',
                      description: task['description'] ?? '',
                    ),
                  ),
                ).then((_) => _refresh()); // Refresh when returning to update tabs
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCompletedList ? Colors.green.withOpacity(0.1) : Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompletedList ? Icons.check_circle : Icons.assignment,
                        color: isCompletedList ? Colors.green : Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['title'] ?? 'Untitled Task', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isCompletedList ? 'Submitted successfully' : 'Tap to start recording',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (!isCompletedList)
                      const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
