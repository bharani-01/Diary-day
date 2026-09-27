import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/cow.dart';
import '../models/breeding_record.dart';
import '../services/database_service.dart';
import 'cow_detail_screen.dart';
import '../widgets/global_drawer.dart';
import '../widgets/cow_image.dart';
import '../widgets/app_ui.dart';
import '../widgets/premium_loading.dart';
import '../constants.dart';

class CalvingAlertsScreen extends StatefulWidget {
  final Function(int) onMenuPressed;
  const CalvingAlertsScreen({super.key, required this.onMenuPressed});

  @override
  State<CalvingAlertsScreen> createState() => _CalvingAlertsScreenState();
}

class _CalvingAlertsScreenState extends State<CalvingAlertsScreen> {
  final _db = DatabaseService();
  List<Map<String, dynamic>> _calvingAlerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final cows = await _db.getCows();
      List<Map<String, dynamic>> alerts = [];

      for (var cow in cows) {
        final records = await _db.getBreedingRecordsForCow(cow.id);
        if (records.isNotEmpty) {
          // Assuming the most recent breeding record is the one to track
          final lastBreeding = records.first.breedingDate;
          final calvingDate = lastBreeding.add(const Duration(days: 283));
          
          if (calvingDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
            final daysToCalving = calvingDate.difference(DateTime.now()).inDays;
            alerts.add({
              'cow': cow,
              'calvingDate': calvingDate,
              'daysToCalving': daysToCalving,
              'breedingDate': lastBreeding,
            });
          }
        }
      }

      // Sort by calving date (soonest first)
      alerts.sort((a, b) => a['calvingDate'].compareTo(b['calvingDate']));

      if (mounted) {
        setState(() {
          _calvingAlerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: GlobalDrawer(currentIndex: 4, onTabSelected: widget.onMenuPressed),
      appBar: AppBar(
        title: const Text('Calving alerts'),
        
        elevation: 0,
        
      ),
      body: _isLoading
          ? const PremiumLoading(message: 'Loading calving alerts…')
          : _calvingAlerts.isEmpty
              ? _buildEmptyState()
              : _buildAlertsList(),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.event_available_outlined,
      title: 'No upcoming calvings',
      message: 'Add breeding records to track expected calving dates.',
    );
  }

  Widget _buildAlertsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _calvingAlerts.length,
      itemBuilder: (context, index) {
        final alert = _calvingAlerts[index];
        final Cow cow = alert['cow'];
        final DateTime calvingDate = alert['calvingDate'];
        final int daysToCalving = alert['daysToCalving'];

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CowDetailScreen(cow: cow)),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: AppConstants.cardDecoration(context),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Stack(
                  children: [
                    // Cow Image
                    CowImage(url: cow.imageUrl, height: 160, width: double.infinity, placeholderIconSize: 56),
                    // Days Remaining Badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getStatusColor(daysToCalving),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          daysToCalving <= 0 ? 'Due today' : '$daysToCalving days left',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ),
                    // Tag Number
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Tag ${cow.tagNumber}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Expected calving', style: TextStyle(color: context.mutedText, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMM d, y').format(calvingDate),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDetailChip(Icons.calendar_today_outlined, 'Bred ${DateFormat('MMM d').format(alert['breedingDate'])}'),
                          _buildDetailChip(Icons.pets_outlined, cow.breed ?? 'Unknown breed'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.mutedText),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: context.mutedText, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getStatusColor(int days) {
    if (days <= 7) return AppConstants.dangerColor;
    if (days <= 30) return AppConstants.warningColor;
    return AppConstants.primaryColor;
  }
}
