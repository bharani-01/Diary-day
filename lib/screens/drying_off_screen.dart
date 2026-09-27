import 'package:flutter/material.dart';
import '../models/cow.dart';
import '../services/database_service.dart';
import '../constants.dart';
import '../widgets/app_ui.dart';
import '../widgets/premium_loading.dart';

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
      appBar: AppBar(
        title: const Text('Drying off'),
        elevation: 0,
      ),
      body: StreamBuilder<List<Cow>>(
        stream: _db.getCowsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const PremiumLoading(message: 'Loading herd…');
          
          final activeCows = snapshot.data!.where((c) => c.status == 'Active').toList();
          
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppConstants.pagePadding),
                itemCount: activeCows.length + 1,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppConstants.infoColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                        border: Border.all(color: AppConstants.infoColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: AppConstants.infoColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Mark cows as dry 60 days before their expected calving date to ensure optimal health.',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final cow = activeCows[index - 1];
                  return AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: IconTile(cow.isDry ? Icons.pause_circle_outline : Icons.water_drop_outlined, color: cow.isDry ? AppConstants.warningColor : null),
                      title: Text('#${cow.tagNumber} ${cow.name ?? ""}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(cow.isDry ? 'Dry' : 'Milking', style: TextStyle(color: cow.isDry ? AppConstants.warningColor : context.mutedText, fontSize: 12)),
                      trailing: Switch(
                        value: cow.isDry,
                        activeColor: AppConstants.warningColor,
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
          );
        }
      ),
    );
  }
}
