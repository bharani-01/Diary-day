import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/cow.dart';
import '../models/breeding_record.dart';
import '../models/health_record.dart';
import '../services/notification_service.dart';
import '../widgets/premium_loading.dart';
import '../widgets/cow_image.dart';
import '../widgets/app_ui.dart';
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
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            shape: const Border(),
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
                        SnackBar(content: Text('Error: $e'), backgroundColor: AppConstants.dangerColor),
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
              title: Text(_currentCow.name != null ? '${_currentCow.tagNumber} "${_currentCow.name}"' : _currentCow.tagNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHeaderBackground(),
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.25, 0.65, 1.0],
                          colors: [Color(0x55000000), Color(0x00000000), Color(0x00000000), Color(0x88000000)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
        color: AppConstants.primaryColor,
        child: const Icon(Icons.pets_outlined, size: 72, color: Colors.white24),
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
                color: _currentPage == index ? Colors.white : Colors.white54,
              ),
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    final healthy = _currentCow.healthStatus == 'Healthy';
    return AppCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildStatItem('Type · breed', '${_currentCow.dynamicCowType} · ${_currentCow.breed ?? 'Native'}', Icons.category_outlined)),
              Expanded(child: _buildStatItem('Age', _currentCow.formattedAge, Icons.cake_outlined)),
              Expanded(child: _buildStatItem('Health', _currentCow.healthStatus, healthy ? Icons.favorite_border : Icons.healing_outlined, color: healthy ? AppConstants.successColor : AppConstants.dangerColor)),
              Expanded(child: _buildStatItem('Status', _currentCow.isDry ? 'Dry' : 'Milking', _currentCow.isDry ? Icons.pause_circle_outline : Icons.water_drop_outlined, color: _currentCow.isDry ? AppConstants.warningColor : null)),
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
                        Icon(Icons.pets_outlined, color: context.mutedText, size: 20),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mother', style: TextStyle(fontSize: 11, color: context.mutedText)),
                            Text(
                              _motherCow!.name != null ? '${_motherCow!.tagNumber} - ${_motherCow!.name}' : _motherCow!.tagNumber,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppConstants.primaryColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Icon(Icons.chevron_right, color: context.mutedText),
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
        Icon(icon, size: 20, color: color ?? context.mutedText),
        const SizedBox(height: 6),
        Text(value, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: context.mutedText)),
      ],
    );
  }

  Widget _buildHistoryTabs() {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppConstants.primaryColor,
        indicatorWeight: 2,
        labelColor: AppConstants.primaryColor,
        unselectedLabelColor: context.mutedText,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
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
          icon: isVaccine ? Icons.vaccines_outlined : Icons.medication_outlined,
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
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          onTap: onTap,
          leading: IconTile(icon, size: 36),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: context.mutedText)),
          trailing: Text(DateFormat('MMM d, y').format(date), style: TextStyle(fontSize: 12, color: context.mutedText)),
        ),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return EmptyState(icon: Icons.history_toggle_off, title: msg);
  }

  Widget _buildTimelineTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _db.getCowTimeline(_currentCow.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const PremiumLoading(message: 'Building Timeline...');
        final events = snapshot.data ?? [];
        if (events.isEmpty) return const EmptyState(icon: Icons.timeline, title: 'No events recorded yet');
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final e = events[index];
            final type = e['type'] as String;
            IconData icon;
            switch (type) {
              case 'health': icon = Icons.medication_outlined; break;
              case 'breeding': icon = Icons.child_care; break;
              case 'milk': icon = Icons.water_drop_outlined; break;
              case 'expense': icon = Icons.currency_rupee; break;
              case 'calf': icon = Icons.child_friendly_outlined; break;
              default: icon = Icons.event_outlined; break;
            }
            final lineColor = Theme.of(context).dividerColor;
            return IntrinsicHeight(
              child: Row(
                children: [
                  // Timeline line
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        if (index > 0) Expanded(child: Container(width: 1.5, color: lineColor)),
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: AppConstants.primaryColor, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).cardColor, width: 2))),
                        if (index < events.length - 1) Expanded(child: Container(width: 1.5, color: lineColor)),
                      ],
                    ),
                  ),
                  // Event card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            IconTile(icon, size: 34),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              if ((e['subtitle'] as String).isNotEmpty) Text(e['subtitle'], style: TextStyle(fontSize: 12, color: context.mutedText)),
                            ])),
                            Text(DateFormat('MMM d').format(e['date']), style: TextStyle(fontSize: 12, color: context.mutedText)),
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
