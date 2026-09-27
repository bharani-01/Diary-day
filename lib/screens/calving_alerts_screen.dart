import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/cow.dart';
import '../models/breeding_record.dart';
import '../services/database_service.dart';
import 'cow_detail_screen.dart';
import '../widgets/global_drawer.dart';
import '../widgets/cow_image.dart';

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
        title: const Text('Maternity & Calving Alerts'),
        
        elevation: 0,
        
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _calvingAlerts.isEmpty
              ? _buildEmptyState()
              : _buildAlertsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notification_important_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No upcoming calvings scheduled',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add breeding records to track maternity',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
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
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    // Cow Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: CowImage(url: cow.imageUrl, height: 180, width: double.infinity, placeholderIconSize: 60),
                    ),
                    // Days Remaining Badge
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(daysToCalving),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)
                          ],
                        ),
                        child: Text(
                          daysToCalving <= 0 ? 'Due Today!' : '$daysToCalving Days Left',
                          style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    // Tag Number
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Tag: ${cow.tagNumber}',
                          style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Expected Calving', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, MMM d, y').format(calvingDate),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.event_note, color: Colors.orange),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildDetailChip(Icons.calendar_today, 'Bred: ${DateFormat('MMM d').format(alert['breedingDate'])}'),
                          const SizedBox(width: 12),
                          _buildDetailChip(Icons.monitor_heart, cow.breed ?? 'Unknown Breed'),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getStatusColor(int days) {
    if (days <= 7) return Colors.red.shade600;
    if (days <= 30) return Colors.orange.shade600;
    return Colors.teal.shade600;
  }
}
