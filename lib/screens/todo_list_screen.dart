import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../constants.dart';
import '../widgets/app_ui.dart';
import '../widgets/premium_loading.dart';

Color _priorityColor(TodoPriority p) {
  switch (p) {
    case TodoPriority.high: return AppConstants.dangerColor;
    case TodoPriority.medium: return AppConstants.warningColor;
    case TodoPriority.low: return const Color(0xFF64748B);
  }
}

String _priorityLabel(TodoPriority p) {
  switch (p) {
    case TodoPriority.high: return 'Urgent';
    case TodoPriority.medium: return 'Important';
    case TodoPriority.low: return 'Normal';
  }
}

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
        title: const Text('Tasks'),
        elevation: 0,
      ),
      body: StreamBuilder<List<Todo>>(
        stream: _db.getTodosStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const PremiumLoading(message: 'Loading tasks…');
          
          final todos = snapshot.data!;
          if (todos.isEmpty) return _buildEmptyState();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: todos.length,
                itemBuilder: (context, index) => _buildTaskCard(todos[index]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context),
        icon: const Icon(Icons.add_task),
        label: const Text('Add task'),
      ),
    );
  }

  Widget _buildTaskCard(Todo todo) {
    final Color priorityColor = _priorityColor(todo.priority);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox Area
            IconButton(
              tooltip: 'Mark done',
              onPressed: () async {
                NotificationService.cancelTaskReminders(todo.id);
                await Future.delayed(const Duration(milliseconds: 300));
                _db.deleteTodo(todo.id);
              },
              icon: Icon(Icons.radio_button_unchecked, color: context.mutedText),
            ),
            const SizedBox(width: 4),
            // Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(todo.task, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusPill(label: _priorityLabel(todo.priority), color: priorityColor),
                        StatusPill(label: todo.category ?? 'Task', color: const Color(0xFF64748B)),
                        if (todo.startTime != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, size: 14, color: context.mutedText),
                              const SizedBox(width: 4),
                              Text(
                                '${DateFormat('hh:mm a').format(todo.startTime!)}${todo.endTime != null ? " – ${DateFormat('hh:mm a').format(todo.endTime!)}" : ""}',
                                style: TextStyle(fontSize: 12, color: context.mutedText),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Delete Button
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline, color: context.mutedText, size: 20),
              onPressed: () => _db.deleteTodo(todo.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.task_alt,
      title: 'No pending tasks',
      message: 'Use Add task to schedule a farm chore.',
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
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('New task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: AppConstants.inputDecoration('What needs to be done? (e.g. Check Cow #102)'),
          ),
          const SizedBox(height: 20),
          
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  showCheckmark: false,
                  onSelected: (val) => setState(() => _category = c),
                  selectedColor: AppConstants.primaryColor.withOpacity(0.12),
                  labelStyle: TextStyle(color: _category == c ? AppConstants.primaryColor : Theme.of(context).colorScheme.onSurface, fontWeight: _category == c ? FontWeight.w600 : FontWeight.normal),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    DropdownButton<TodoPriority>(
                      value: _priority,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: TodoPriority.values.map((p) => DropdownMenuItem(
                        value: p, 
                        child: Row(children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: _priorityColor(p), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(_priorityLabel(p)),
                        ]),
                      )).toList(),
                      onChanged: (val) => setState(() => _priority = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Schedule', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: _pickTime,
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), alignment: Alignment.centerLeft),
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Text(_startTime == null ? 'Set time' : DateFormat('hh:mm a').format(_startTime!)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: primaryButtonStyle(),
              child: const Text('Schedule task'),
            ),
          ),
        ],
      ),
    );
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
