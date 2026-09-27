import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/health_record.dart';
import '../constants.dart';
import '../widgets/app_ui.dart';

class HealthRecordDetailScreen extends StatelessWidget {
  final HealthRecord record;

  const HealthRecordDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final bool isVaccine = record.type == 'Vaccination';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health record'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconTile(isVaccine ? Icons.vaccines_outlined : Icons.medication_outlined, color: AppConstants.primaryColor, size: 44),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusPill(label: record.type, color: AppConstants.primaryColor),
                            const SizedBox(height: 8),
                            Text(record.treatment, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(DateFormat('MMMM d, yyyy').format(record.date), style: TextStyle(color: context.mutedText, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.sectionGap),
                
                // Details Section
                const SectionHeader('Details'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _detailTile(context, Icons.person_outline, 'Administered by', record.administeredBy ?? 'Self'),
                      const Divider(height: 1),
                      _detailTile(context, Icons.category_outlined, 'Category', record.type),
                      const Divider(height: 1),
                      _detailTile(context, Icons.calendar_today_outlined, 'Date of treatment', DateFormat('EEEE, MMM d, yyyy').format(record.date)),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppConstants.sectionGap),
                const SectionHeader('Notes'),
                AppCard(
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      record.notes ?? 'No additional notes for this record.',
                      style: TextStyle(color: record.notes == null ? context.mutedText : Theme.of(context).colorScheme.onSurface, height: 1.5, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailTile(BuildContext context, IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, size: 20, color: context.mutedText),
      title: Text(label, style: TextStyle(color: context.mutedText, fontSize: 12)),
      subtitle: Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
    );
  }
}
