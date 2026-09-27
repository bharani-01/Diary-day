import 'package:flutter/material.dart';
import '../models/cow.dart';
import '../services/database_service.dart';
import '../constants.dart';

class DryingOffScreen extends StatefulWidget {
  const DryingOffScreen({super.key});

  @override
  State<DryingOffScreen> createState() => _DryingOffScreenState();
}

class _DryingOffScreenState extends State<DryingOffScreen> {
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        title: Text('Drying-Off Logger', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: StreamBuilder<List<Cow>>(
        stream: _db.getCowsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final activeCows = snapshot.data!.where((c) => c.status == 'Active').toList();
          
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.indigo),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mark cows as "Dry" 60 days before their expected calving date to ensure optimal health.',
                        style: TextStyle(color: Colors.indigo.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: activeCows.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cow = activeCows[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: cow.isDry ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          child: Icon(cow.isDry ? Icons.pause_circle_filled : Icons.play_circle_fill, color: cow.isDry ? Colors.orange : Colors.green),
                        ),
                        title: Text('#${cow.tagNumber} ${cow.name ?? ""}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(cow.isDry ? 'Status: Dry' : 'Status: Milking', style: TextStyle(color: cow.isDry ? Colors.orange : Colors.green, fontSize: 12)),
                        trailing: Switch(
                          value: cow.isDry,
                          activeColor: Colors.orange,
                          onChanged: (val) async {
                            try {
                              await _db.markAsDry(cow.id, val);
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}
