import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../constants.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Farm Task Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        
        elevation: 0,
        
      ),
      body: StreamBuilder<List<Todo>>(
        stream: _db.getTodosStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final todos = snapshot.data!;
          if (todos.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            itemCount: todos.length,
            itemBuilder: (context, index) => _buildTaskCard(todos[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context),
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: Text('Add New Task', style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTaskCard(Todo todo) {
    final Color priorityColor = _getPriorityColor(todo.priority);
    final String priorityText = _getPriorityLabel(todo.priority);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Priority Bar
            Container(
              height: 4,
              width: double.infinity,
              color: priorityColor,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox Area
                  InkWell(
                    onTap: () async {
                      NotificationService.cancelTaskReminders(todo.id);
                      await Future.delayed(const Duration(milliseconds: 300));
                      _db.deleteTodo(todo.id);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppConstants.primaryColor, width: 2),
                      ),
                      child: const Icon(Icons.check, size: 18, color: Colors.transparent),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content Area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(todo.task, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildTag(todo.category ?? 'Task', Colors.blue),
                            const SizedBox(width: 8),
                            _buildTag(priorityText, priorityColor),
                          ],
                        ),
                        if (todo.startTime != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time_filled, size: 14, color: Colors.blue.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  'Scheduled: ${DateFormat('hh:mm a').format(todo.startTime!)} ${todo.endTime != null ? " - ${DateFormat('hh:mm a').format(todo.endTime!)}" : ""}',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Delete Button
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                    onPressed: () => _db.deleteTodo(todo.id),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)),
    );
  }

  Color _getPriorityColor(TodoPriority p) {
    switch (p) {
      case TodoPriority.high: return Colors.red.shade400;
      case TodoPriority.medium: return Colors.orange.shade400;
      case TodoPriority.low: return Colors.green.shade400;
    }
  }

  String _getPriorityLabel(TodoPriority p) {
    switch (p) {
      case TodoPriority.high: return 'Urgent';
      case TodoPriority.medium: return 'Important';
      case TodoPriority.low: return 'Normal';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text('No pending tasks!', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const Text('Tap "+" to add a farm chore', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTaskBottomSheet(),
    );
  }
}

class AddTaskBottomSheet extends StatefulWidget {
  const AddTaskBottomSheet({super.key});

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final _controller = TextEditingController();
  final _db = DatabaseService();
  
  TodoPriority _priority = TodoPriority.medium;
  String _category = 'Feeding';
  DateTime? _startTime;
  DateTime? _endTime;

  final List<String> _categories = ['Feeding', 'Medical', 'Cleaning', 'Milking', 'General'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create New Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: AppConstants.inputDecoration('What needs to be done? (e.g. Check Cow #102)'),
          ),
          const SizedBox(height: 24),
          
          const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (val) => setState(() => _category = c),
                  selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: _category == c ? AppConstants.primaryColor : Colors.grey, fontWeight: FontWeight.bold),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    DropdownButton<TodoPriority>(
                      value: _priority,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: TodoPriority.values.map((p) => DropdownMenuItem(
                        value: p, 
                        child: Text(_getPriorityLabel(p), style: TextStyle(color: _getPriorityColor(p))),
                      )).toList(),
                      onChanged: (val) => setState(() => _priority = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(_startTime == null ? 'Set Time' : DateFormat('hh:mm a').format(_startTime!), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Schedule Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  String _getPriorityLabel(TodoPriority p) {
    switch (p) {
      case TodoPriority.high: return '🔴 Urgent';
      case TodoPriority.medium: return '🟠 Important';
      case TodoPriority.low: return '🟢 Normal';
    }
  }

  Color _getPriorityColor(TodoPriority p) {
    switch (p) {
      case TodoPriority.high: return Colors.red;
      case TodoPriority.medium: return Colors.orange;
      case TodoPriority.low: return Colors.green;
    }
  }

  Future<void> _pickTime() async {
    final start = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (start == null) return;
    
    final end = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))));
    
    setState(() {
      final now = DateTime.now();
      _startTime = DateTime(now.year, now.month, now.day, start.hour, start.minute);
      if (end != null) _endTime = DateTime(now.year, now.month, now.day, end.hour, end.minute);
    });
  }

  void _save() async {
    if (_controller.text.isEmpty) return;
    
    final todo = Todo(
      id: '',
      task: _controller.text,
      createdAt: DateTime.now(),
      priority: _priority,
      category: _category,
      startTime: _startTime,
      endTime: _endTime,
    );

    try {
      final id = await _db.addTodo(todo);
      if (_startTime != null) {
        await NotificationService.scheduleTodoReminders(id: id, task: todo.task, startTime: _startTime, endTime: _endTime);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
