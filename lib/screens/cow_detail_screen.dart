import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/cow.dart';
import '../models/breeding_record.dart';
import '../models/health_record.dart';
import '../services/notification_service.dart';
import '../widgets/premium_loading.dart';
import '../widgets/cow_image.dart';
import '../services/database_service.dart';
import '../services/report_service.dart';
import 'add_breeding_record_screen.dart';
import 'add_health_record_screen.dart';
import 'add_cow_screen.dart';
import 'health_record_detail_screen.dart';

class CowDetailScreen extends StatefulWidget {
  final Cow cow;

  const CowDetailScreen({super.key, required this.cow});

  @override
  State<CowDetailScreen> createState() => _CowDetailScreenState();
}

class _CowDetailScreenState extends State<CowDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentPage = 0;
  final _db = DatabaseService();
  List<BreedingRecord> _breedingRecords = [];
  List<HealthRecord> _healthRecords = [];
  bool _isLoading = true;
  Cow? _motherCow;
  late Cow _currentCow;

  @override
  void initState() {
    super.initState();
    _currentCow = widget.cow;
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();
    _fetchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final breeding = await _db.getBreedingRecordsForCow(_currentCow.id);
      final health = await _db.getHealthRecordsForCow(_currentCow.id);
      Cow? mother;
      if (_currentCow.motherCowId != null) {
        mother = await _db.getCow(_currentCow.motherCowId!);
      }
      setState(() {
        _breedingRecords = breeding;
        _healthRecords = health;
        _motherCow = mother;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                tooltip: 'Export Profile',
                onPressed: () async {
                  try {
                    final healthMaps = _healthRecords.map((r) => <String, String>{
                      'date': DateFormat('yyyy-MM-dd').format(r.date),
                      'treatment': r.treatment,
                      'type': r.type,
                      'administeredBy': r.administeredBy ?? 'Self',
                    }).toList();
                    final breedingMaps = _breedingRecords.map((r) => <String, String>{
                      'date': DateFormat('yyyy-MM-dd').format(r.breedingDate),
                      'details': r.details ?? 'No details',
                    }).toList();

                    await ReportService().generateCowProfilePdf(
                      tagNumber: _currentCow.tagNumber,
                      name: _currentCow.name,
                      age: _currentCow.formattedAge,
                      type: _currentCow.dynamicCowType,
                      breed: _currentCow.breed,
                      healthStatus: _currentCow.healthStatus,
                      healthRecords: healthMaps,
                      breedingRecords: breedingMaps,
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddCowScreen(existingCow: _currentCow)),
                  );
                  if (result == true) {
                    final updatedCow = await _db.getCow(_currentCow.id);
                    if (updatedCow != null && mounted) {
                      setState(() {
                        _currentCow = updatedCow;
                      });
                      _fetchHistory();
                    }
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_currentCow.name != null ? '${_currentCow.tagNumber} "${_currentCow.name}"' : _currentCow.tagNumber, style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold)),
              background: _buildHeaderBackground(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  _buildHistoryTabs(),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBreedingTab(),
                _buildHealthTab(),
                _buildTimelineTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderBackground() {
    final urls = _currentCow.imageUrls ?? (_currentCow.imageUrl != null ? [_currentCow.imageUrl!] : []);
    
    if (urls.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppConstants.primaryColor, Colors.teal.shade700]),
        ),
        child: const Icon(Icons.pets, size: 80, color: Colors.white24),
      );
    }

    if (urls.length == 1) {
      return CowImage(url: urls.first, placeholderIconSize: 80);
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemCount: urls.length,
          itemBuilder: (context, index) => CowImage(url: urls[index], placeholderIconSize: 80),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(urls.length, (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentPage == index ? AppConstants.primaryColor : Colors.white70,
              ),
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Type / Breed', '${_currentCow.dynamicCowType} • ${_currentCow.breed ?? 'Native'}', Icons.category),
              _buildStatItem('Age', _currentCow.formattedAge, Icons.calendar_today),
              _buildStatItem('Health', _currentCow.healthStatus, Icons.favorite, color: Colors.green),
              _buildStatItem('Status', _currentCow.isDry ? 'Dry' : 'Milking', _currentCow.isDry ? Icons.pause_circle_outline : Icons.play_circle_outline, color: _currentCow.isDry ? Colors.orange : Colors.blue),
            ],
          ),
          if (_motherCow != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CowDetailScreen(cow: _motherCow!),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pets, color: Colors.purple, size: 20),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mother', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text(
                              _motherCow!.name != null ? '${_motherCow!.tagNumber} - ${_motherCow!.name}' : _motherCow!.tagNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildHistoryTabs() {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(color: AppConstants.primaryColor, borderRadius: BorderRadius.circular(10)),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Breeding'),
          Tab(text: 'Health'),
          Tab(text: 'Timeline'),
        ],
      ),
    );
  }

  Widget _buildBreedingTab() {
    if (_isLoading) return const PremiumLoading(message: 'Fetching Breeding History...');
    if (_breedingRecords.isEmpty) return _emptyState('No breeding records found');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _breedingRecords.length,
      itemBuilder: (context, index) {
        final r = _breedingRecords[index];
        return _buildHistoryTile(
          date: r.breedingDate,
          title: 'Breeding Event',
          subtitle: r.details ?? 'No details provided',
          icon: Icons.child_care,
          color: Colors.blue,
        );
      },
    );
  }

  Widget _buildHealthTab() {
    if (_isLoading) return const PremiumLoading(message: 'Fetching Health Records...');
    if (_healthRecords.isEmpty) return _emptyState('No medical history found');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _healthRecords.length,
      itemBuilder: (context, index) {
        final r = _healthRecords[index];
        bool isVaccine = r.type == 'Vaccination';
        return _buildHistoryTile(
          date: r.date,
          title: r.treatment,
          subtitle: '${r.type} • ${r.administeredBy ?? "Self"}',
          icon: isVaccine ? Icons.vaccines : Icons.medication,
          color: isVaccine ? Colors.teal : Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HealthRecordDetailScreen(record: r)),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTile({
    required DateTime date, 
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Text(DateFormat('MMM d').format(date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _db.getCowTimeline(_currentCow.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const PremiumLoading(message: 'Building Timeline...');
        final events = snapshot.data ?? [];
        if (events.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.timeline, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('No events recorded yet', style: TextStyle(fontSize: 16, color: Theme.of(context).cardColor))]));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final e = events[index];
            final type = e['type'] as String;
            Color color;
            IconData icon;
            switch (type) {
              case 'health': color = Colors.orange; icon = Icons.medication; break;
              case 'breeding': color = Colors.blue; icon = Icons.child_care; break;
              case 'milk': color = Colors.teal; icon = Icons.water_drop; break;
              case 'expense': color = Colors.red; icon = Icons.currency_rupee; break;
              case 'calf': color = Colors.pink; icon = Icons.child_friendly; break;
              default: color = Colors.grey; icon = Icons.event; break;
            }
            return IntrinsicHeight(
              child: Row(
                children: [
                  // Timeline line
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        if (index > 0) Expanded(child: Container(width: 2, color: Colors.grey.shade200)),
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        if (index < events.length - 1) Expanded(child: Container(width: 2, color: Colors.grey.shade200)),
                      ],
                    ),
                  ),
                  // Event card
                  Expanded(
                    child: Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.2))),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 18, child: Icon(icon, color: color, size: 18)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              if ((e['subtitle'] as String).isNotEmpty) Text(e['subtitle'], style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                            ])),
                            Text(DateFormat('MMM d').format(e['date']), style: TextStyle(fontSize: 11, color: Theme.of(context).cardColor)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onFabPressed() async {
    if (_tabController.index == 0) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddBreedingRecordScreen(cowId: _currentCow.id)),
      );
      if (result == true) _fetchHistory();
    } else if (_tabController.index == 1) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddHealthRecordScreen(cowId: _currentCow.id)),
      );
      if (result == true) _fetchHistory();
    }
    // Timeline tab (index 2) - no FAB action needed
  }
}
