import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants.dart';

class FarmNote {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String category; // 'vaccination', 'breeding', 'payment', 'general'

  FarmNote({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'category': category,
  };

  factory FarmNote.fromJson(Map<String, dynamic> json) => FarmNote(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    date: DateTime.parse(json['date']),
    category: json['category'] ?? 'general',
  );
}

class FarmCalendarScreen extends StatefulWidget {
  const FarmCalendarScreen({super.key});

  @override
  State<FarmCalendarScreen> createState() => _FarmCalendarScreenState();
}

class _FarmCalendarScreenState extends State<FarmCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<FarmNote> _allNotes = [];
  bool _showCalendarView = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // Persistence via SharedPreferences (lightweight, no extra Supabase table needed)
  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString('farm_notes');
    if (notesJson != null) {
      final List decoded = json.decode(notesJson);
      setState(() {
        _allNotes = decoded.map((n) => FarmNote.fromJson(n)).toList();
      });
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_allNotes.map((n) => n.toJson()).toList());
    await prefs.setString('farm_notes', encoded);
  }

  List<FarmNote> _getNotesForDay(DateTime day) {
    return _allNotes.where((note) =>
      note.date.year == day.year &&
      note.date.month == day.month &&
      note.date.day == day.day
    ).toList();
  }

  void _addNote() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'general';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Note — ${DateFormat('MMM d, yyyy').format(_selectedDay)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category chips
                Wrap(
                  spacing: 8,
                  children: [
                    _buildCategoryChip('general', '📝 General', selectedCategory, (val) => setModalState(() => selectedCategory = val)),
                    _buildCategoryChip('vaccination', '💉 Vaccination', selectedCategory, (val) => setModalState(() => selectedCategory = val)),
                    _buildCategoryChip('breeding', '🐄 Breeding', selectedCategory, (val) => setModalState(() => selectedCategory = val)),
                    _buildCategoryChip('payment', '💰 Payment', selectedCategory, (val) => setModalState(() => selectedCategory = val)),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) return;
                      final note = FarmNote(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        date: _selectedDay,
                        category: selectedCategory,
                      );
                      setState(() => _allNotes.add(note));
                      _saveNotes();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save Note', style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteNote(FarmNote note) {
    setState(() => _allNotes.removeWhere((n) => n.id == note.id));
    _saveNotes();
  }

  Widget _buildCategoryChip(String value, String label, String selected, Function(String) onSelect) {
    final isSelected = selected == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      onSelected: (_) => onSelect(value),
      selectedColor: AppConstants.primaryColor,
      backgroundColor: Theme.of(context).dividerColor,
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'vaccination': return Colors.purple;
      case 'breeding': return Colors.blue;
      case 'payment': return Colors.green;
      default: return Colors.orange;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'vaccination': return Icons.vaccines;
      case 'breeding': return Icons.child_care;
      case 'payment': return Icons.payments;
      default: return Icons.note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesForSelected = _getNotesForDay(_selectedDay);

    // For notes list view: group all notes by date
    final sortedNotes = List<FarmNote>.from(_allNotes)..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Farm Calendar'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showCalendarView ? Icons.list : Icons.calendar_month),
            tooltip: _showCalendarView ? 'Notes View' : 'Calendar View',
            onPressed: () => setState(() => _showCalendarView = !_showCalendarView),
          ),
        ],
      ),
      body: _showCalendarView ? _buildCalendarView(notesForSelected) : _buildNotesListView(sortedNotes),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCalendarView(List<FarmNote> notesForSelected) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getNotesForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppConstants.primaryColor,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              markerSize: 6,
              markersMaxCount: 3,
            ),
            headerStyle: HeaderStyle(
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: AppConstants.primaryColor),
                borderRadius: BorderRadius.circular(12),
              ),
              formatButtonTextStyle: const TextStyle(color: AppConstants.primaryColor, fontSize: 12),
              titleCentered: true,
              titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        // Date label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, MMM d, yyyy').format(_selectedDay),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                '${notesForSelected.length} note${notesForSelected.length != 1 ? 's' : ''}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
              ),
            ],
          ),
        ),
        // Notes for selected day
        Expanded(
          child: notesForSelected.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_note, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('No notes for this day', style: TextStyle(color: Theme.of(context).cardColor)),
                      const SizedBox(height: 4),
                      Text('Tap + to add one', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notesForSelected.length,
                  itemBuilder: (context, index) => _buildNoteCard(notesForSelected[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildNotesListView(List<FarmNote> sortedNotes) {
    if (sortedNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No notes yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Tap + to create your first note', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    // Group notes by date
    Map<String, List<FarmNote>> grouped = {};
    for (var note in sortedNotes) {
      final key = DateFormat('yyyy-MM-dd').format(note.date);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(note);
    }

    final dateKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dateKeys.length,
      itemBuilder: (context, index) {
        final dateKey = dateKeys[index];
        final notes = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                DateFormat('EEEE, MMM d, yyyy').format(date),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              ),
            ),
            ...notes.map((note) => _buildNoteCard(note)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildNoteCard(FarmNote note) {
    final color = _getCategoryColor(note.category);
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) => _deleteNote(note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getCategoryIcon(note.category), color: color, size: 20),
          ),
          title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: note.description.isNotEmpty
              ? Text(note.description, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), maxLines: 2, overflow: TextOverflow.ellipsis)
              : null,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              note.category[0].toUpperCase() + note.category.substring(1),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
