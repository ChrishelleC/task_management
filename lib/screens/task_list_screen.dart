import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'auth_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _auth = FirebaseAuth.instance;
  final _taskController = TextEditingController();
  final _subTaskController = TextEditingController();
  String selectedPriority = 'Medium';
  DateTime selectedDate = DateTime.now();

  String sortBy = 'dueDate';
  String? filterPriority;
  bool showCompleted = true;

  CollectionReference get taskRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('tasks');

  void _addTask() async {
    if (_taskController.text.trim().isEmpty) return;

    final task = Task(
      id: '',
      name: _taskController.text.trim(),
      isCompleted: false,
      priority: selectedPriority,
      dueDate: selectedDate,
      timeSlots: [],
    );

    await taskRef.add(task.toMap());
    _taskController.clear();
  }

  void _deleteTask(String id) {
    taskRef.doc(id).delete();
  }

  void _toggleCompletion(Task task) {
    taskRef.doc(task.id).update({'isCompleted': !task.isCompleted});
  }

  void _addSubTask(String taskId, String timeRange, String subTaskName) async {
    final doc = await taskRef.doc(taskId).get();
    final task = Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    final existingSlot = task.timeSlots.firstWhere(
      (slot) => slot.timeRange == timeRange,
      orElse: () => SubTaskSlot(timeRange: timeRange, tasks: []),
    );

    if (!task.timeSlots.contains(existingSlot)) {
      task.timeSlots.add(existingSlot);
    }

    existingSlot.tasks.add(subTaskName);

    await taskRef.doc(taskId).update({'timeSlots': task.timeSlots.map((e) => e.toMap()).toList()});
  }

  List<Task> _sortAndFilter(List<Task> tasks) {
    if (filterPriority != null) {
      tasks = tasks.where((t) => t.priority == filterPriority).toList();
    }

    if (!showCompleted) {
      tasks = tasks.where((t) => !t.isCompleted).toList();
    }

    switch (sortBy) {
      case 'priority':
        tasks.sort((a, b) => _priorityValue(b.priority).compareTo(_priorityValue(a.priority)));
        break;
      case 'completion':
        tasks.sort((a, b) => a.isCompleted ? 1 : -1);
        break;
      case 'dueDate':
      default:
        tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    }

    return tasks;
  }

  int _priorityValue(String p) {
    switch (p) {
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      case 'Low':
        return 1;
      default:
        return 0;
    }
  }

  void _logout() async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          _buildTaskInput(),
          _buildFilters(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: taskRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                List<Task> tasks = snapshot.data!.docs.map((doc) {
                  return Task.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                }).toList();

                tasks = _sortAndFilter(tasks);

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (_, index) {
                    final task = tasks[index];
                    return _buildTaskTile(task);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskInput() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _taskController,
              decoration: const InputDecoration(labelText: 'New Task'),
            ),
          ),
          DropdownButton<String>(
            value: selectedPriority,
            items: ['High', 'Medium', 'Low']
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (value) => setState(() => selectedPriority = value!),
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: _addTask),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          DropdownButton<String>(
            value: sortBy,
            items: const [
              DropdownMenuItem(value: 'dueDate', child: Text('Due Date')),
              DropdownMenuItem(value: 'priority', child: Text('Priority')),
              DropdownMenuItem(value: 'completion', child: Text('Completion')),
            ],
            onChanged: (value) => setState(() => sortBy = value!),
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            hint: const Text('Filter by Priority'),
            value: filterPriority,
            items: [null, 'High', 'Medium', 'Low']
                .map((p) => DropdownMenuItem(value: p, child: Text(p ?? 'All')))
                .toList(),
            onChanged: (value) => setState(() => filterPriority = value),
          ),
          const SizedBox(width: 10),
          Checkbox(
            value: showCompleted,
            onChanged: (val) => setState(() => showCompleted = val!),
          ),
          const Text('Show Completed'),
        ],
      ),
    );
  }

  Widget _buildTaskTile(Task task) {
    Color priorityColor;
    switch (task.priority) {
      case 'High':
        priorityColor = Colors.red;
        break;
      case 'Medium':
        priorityColor = Colors.orange;
        break;
      case 'Low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      child: ExpansionTile(
        title: Row(
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (_) => _toggleCompletion(task),
            ),
            Expanded(child: Text(task.name)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.priority,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteTask(task.id),
            ),
          ],
        ),
        subtitle: Text('Due: ${task.dueDate.toLocal().toString().split(' ')[0]}'),
        children: [
          ...task.timeSlots.map((slot) => ListTile(
                title: Text(slot.timeRange),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: slot.tasks.map((t) => Text('- $t')).toList(),
                ),
              )),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subTaskController,
                    decoration: const InputDecoration(hintText: 'Subtask'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_subTaskController.text.isEmpty) return;
                    _addSubTask(task.id, "9am-10am", _subTaskController.text.trim());
                    _subTaskController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
