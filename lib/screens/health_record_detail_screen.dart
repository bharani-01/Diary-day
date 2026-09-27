import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/health_record.dart';
import '../constants.dart';

class HealthRecordDetailScreen extends StatelessWidget {
  final HealthRecord record;

  const HealthRecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final bool isVaccine = record.type == 'Vaccination';
    final Color themeColor = isVaccine ? Colors.teal : Colors.orange;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Record Details'),
        
        
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeColor, themeColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                        child: Text(record.type, style: TextStyle(color: Theme.of(context).cardColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Icon(Icons.verified, color: Theme.of(context).cardColor, size: 24),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(record.treatment, style: TextStyle(color: Theme.of(context).cardColor, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(DateFormat('MMMM d, yyyy').format(record.date), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Details Section
            const Text('RECORD INFORMATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            _detailTile(context, Icons.person, 'Administered By', record.administeredBy ?? 'Self'),
            _detailTile(context, Icons.category, 'Category', record.type),
            _detailTile(context, Icons.calendar_today, 'Date of Treatment', DateFormat('EEEE, MMM d, yyyy').format(record.date)),
            
            const SizedBox(height: 32),
            const Text('NOTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Text(
                record.notes ?? 'No additional notes provided for this record.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, height: 1.5, fontSize: 14, fontStyle: record.notes == null ? FontStyle.italic : FontStyle.normal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: AppConstants.primaryColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
