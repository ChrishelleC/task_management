class Task {
  String id;
  String name;
  bool isCompleted;
  String priority;
  DateTime dueDate;
  List<SubTaskSlot> timeSlots;

  Task({
    required this.id,
    required this.name,
    this.isCompleted = false,
    required this.priority,
    required this.dueDate,
    required this.timeSlots,
  });

  factory Task.fromMap(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      name: data['name'],
      isCompleted: data['isCompleted'],
      priority: data['priority'],
      dueDate: data['dueDate'],
      timeSlots: (data['timeSlots'] as List<dynamic>)
          .map((slot) => SubTaskSlot.fromMap(slot))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'isCompleted': isCompleted,
        'priority': priority,
        'dueDate': dueDate,
        'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
      };
}

class SubTaskSlot {
  String timeRange;
  List<String> tasks;

  SubTaskSlot({required this.timeRange, required this.tasks});

  factory SubTaskSlot.fromMap(Map<String, dynamic> data) {
    return SubTaskSlot(
      timeRange: data['timeRange'],
      tasks: List<String>.from(data['tasks']),
    );
  }

  Map<String, dynamic> toMap() => {
        'timeRange': timeRange,
        'tasks': tasks,
      };
}