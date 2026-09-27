import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants.dart';
import '../services/database_service.dart';
import '../models/shift_milk_entry.dart';
import '../widgets/global_drawer.dart';
import '../widgets/app_ui.dart';
import '../widgets/global_error_view.dart';
import '../widgets/premium_loading.dart';

enum SortOption {
  dateDesc,
  dateAsc,
  litersDesc,
  litersAsc,
  fatDesc,
  fatAsc,
  snfDesc,
  snfAsc,
}

class MilkHistoryScreen extends StatefulWidget {
  final Function(int) onMenuPressed;
  const MilkHistoryScreen({super.key, required this.onMenuPressed});

  @override
  State<MilkHistoryScreen> createState() => _MilkHistoryScreenState();
}

class _MilkHistoryScreenState extends State<MilkHistoryScreen> {
  final _db = DatabaseService();
  List<ShiftMilkEntry> _allRecords = [];
  List<ShiftMilkEntry> _filteredRecords = [];
  String _selectedFilter = 'All';
  DateTimeRange? _customRange;
  SortOption _selectedSort = SortOption.dateDesc;


  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _customRange,
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedFilter = 'Custom';
      });
    }
  }

  void _applySort() {
    switch (_selectedSort) {
      case SortOption.dateDesc:
        _filteredRecords.sort((a, b) => b.entryDate.compareTo(a.entryDate));
        break;
      case SortOption.dateAsc:
        _filteredRecords.sort((a, b) => a.entryDate.compareTo(b.entryDate));
        break;
      case SortOption.litersDesc:
        _filteredRecords.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case SortOption.litersAsc:
        _filteredRecords.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case SortOption.fatDesc:
        _filteredRecords.sort((a, b) => (b.fatPercentage ?? 0).compareTo(a.fatPercentage ?? 0));
        break;
      case SortOption.fatAsc:
        _filteredRecords.sort((a, b) => (a.fatPercentage ?? 0).compareTo(b.fatPercentage ?? 0));
        break;
      case SortOption.snfDesc:
        _filteredRecords.sort((a, b) => (b.snf ?? 0).compareTo(a.snf ?? 0));
        break;
      case SortOption.snfAsc:
        _filteredRecords.sort((a, b) => (a.snf ?? 0).compareTo(b.snf ?? 0));
        break;
    }
  }

  void _filterRecords() {
    final now = DateTime.now();
    if (_selectedFilter == 'All') {
      _filteredRecords = List.from(_allRecords);
    } else if (_selectedFilter == 'Today') {
      _filteredRecords = _allRecords.where((r) => r.entryDate.year == now.year && r.entryDate.month == now.month && r.entryDate.day == now.day).toList();
    } else if (_selectedFilter == 'Last 7 Days') {
      _filteredRecords = _allRecords.where((r) => r.entryDate.isAfter(now.subtract(const Duration(days: 7)))).toList();
    } else if (_selectedFilter == 'This Month') {
      _filteredRecords = _allRecords.where((r) => r.entryDate.year == now.year && r.entryDate.month == now.month).toList();
    } else if (_selectedFilter == 'Custom' && _customRange != null) {
      _filteredRecords = _allRecords.where((r) => r.entryDate.isAfter(_customRange!.start.subtract(const Duration(days: 1))) && r.entryDate.isBefore(_customRange!.end.add(const Duration(days: 1)))).toList();
    }
    _applySort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalDrawer(currentIndex: 1, onTabSelected: widget.onMenuPressed),
      appBar: AppBar(
        title: const Text('Milk history'),
        elevation: 0,
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort records',
            onSelected: (SortOption result) {
              setState(() => _selectedSort = result);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(value: SortOption.dateDesc, child: Text('Date (newest first)')),
              const PopupMenuItem<SortOption>(value: SortOption.dateAsc, child: Text('Date (oldest first)')),
              const PopupMenuDivider(),
              const PopupMenuItem<SortOption>(value: SortOption.litersDesc, child: Text('Litres (high to low)')),
              const PopupMenuItem<SortOption>(value: SortOption.litersAsc, child: Text('Litres (low to high)')),
              const PopupMenuDivider(),
              const PopupMenuItem<SortOption>(value: SortOption.fatDesc, child: Text('Fat % (high to low)')),
              const PopupMenuItem<SortOption>(value: SortOption.fatAsc, child: Text('Fat % (low to high)')),
              const PopupMenuDivider(),
              const PopupMenuItem<SortOption>(value: SortOption.snfDesc, child: Text('SNF (high to low)')),
              const PopupMenuItem<SortOption>(value: SortOption.snfAsc, child: Text('SNF (low to high)')),
            ],
          ),
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickDateRange, tooltip: 'Pick date range'),
        ],
      ),
      body: StreamBuilder<List<ShiftMilkEntry>>(
        stream: _db.getShiftMilkEntriesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return GlobalErrorView(error: snapshot.error!);
          if (!snapshot.hasData) return const PremiumLoading(message: 'Loading milk records…');

          _allRecords = snapshot.data!;
          _filterRecords();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildStatsHeader()),
                  SliverToBoxAdapter(child: _buildYieldComparisonChart()),
                  SliverToBoxAdapter(child: _buildFilterChips()),
                  if (_filteredRecords.isEmpty)
                    SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildMilkRecordCard(_filteredRecords[index]),
                          childCount: _filteredRecords.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final last30DaysRecords = _allRecords.where((r) => r.entryDate.isAfter(thirtyDaysAgo)).toList();
    
    double total = _filteredRecords.fold(0, (sum, r) => sum + r.quantity);
    
    double avgFat30 = last30DaysRecords.isEmpty 
        ? 0 
        : last30DaysRecords.where((r) => r.fatPercentage != null).fold(0.0, (sum, r) => sum + r.fatPercentage!) / 
          (last30DaysRecords.where((r) => r.fatPercentage != null).length.clamp(1, 999999));
          
    double avgSnf30 = last30DaysRecords.isEmpty 
        ? 0 
        : last30DaysRecords.where((r) => r.snf != null).fold(0.0, (sum, r) => sum + r.snf!) / 
          (last30DaysRecords.where((r) => r.snf != null).length.clamp(1, 999999));
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            Expanded(child: _statItem('Total', total.toStringAsFixed(1), 'L')),
            Expanded(child: _statItem('Entries', _filteredRecords.length.toString(), '')),
            Expanded(child: _statItem('Avg SNF · 30d', avgSnf30.toStringAsFixed(2), '')),
            Expanded(child: _statItem('Avg fat · 30d', avgFat30.toStringAsFixed(2), '%')),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, textAlign: TextAlign.center, style: TextStyle(color: context.mutedText, fontSize: 11)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              if (unit.isNotEmpty) Text(' $unit', style: TextStyle(color: context.mutedText, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  static const Color _morningColor = AppConstants.primaryColor;
  static const Color _eveningColor = Color(0xFF64748B);

  Widget _legendDot(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: context.mutedText)),
      ]);

  Widget _buildYieldComparisonChart() {
    final now = DateTime.now();
    final days = 30;
    List<FlSpot> morningSpots = [];
    List<FlSpot> eveningSpots = [];
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final morningTotal = _allRecords.where((r) => DateFormat('yyyy-MM-dd').format(r.entryDate) == dateStr && r.shift == 'Morning').fold(0.0, (s, r) => s + r.quantity);
      final eveningTotal = _allRecords.where((r) => DateFormat('yyyy-MM-dd').format(r.entryDate) == dateStr && r.shift == 'Evening').fold(0.0, (s, r) => s + r.quantity);
      morningSpots.add(FlSpot((days - 1 - i).toDouble(), morningTotal));
      eveningSpots.add(FlSpot((days - 1 - i).toDouble(), eveningTotal));
    }
    
    final hasData = morningSpots.any((s) => s.y > 0) || eveningSpots.any((s) => s.y > 0);
    if (!hasData) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Morning vs evening · 30 days', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                _legendDot(_morningColor, 'Morning'),
                _legendDot(_eveningColor, 'Evening'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: LineChart(LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: TextStyle(fontSize: 9, color: context.mutedText)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 7, getTitlesWidget: (v, _) {
                    final date = now.subtract(Duration(days: days - 1 - v.toInt()));
                    return Padding(padding: const EdgeInsets.only(top: 4), child: Text(DateFormat('d/M').format(date), style: TextStyle(fontSize: 9, color: context.mutedText)));
                  })),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(spots: morningSpots, color: _morningColor, barWidth: 2, dotData: FlDotData(show: false), belowBarData: BarAreaData(show: true, color: _morningColor.withOpacity(0.06))),
                  LineChartBarData(spots: eveningSpots, color: _eveningColor, barWidth: 2, dotData: FlDotData(show: false)),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: ['All', 'Today', 'Last 7 Days', 'This Month', 'Custom'].map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (filter == 'Custom' && selected) {
                  _pickDateRange();
                } else {
                  setState(() => _selectedFilter = filter);
                }
              },
              selectedColor: AppConstants.primaryColor.withOpacity(0.12),
              labelStyle: TextStyle(color: isSelected ? AppConstants.primaryColor : Theme.of(context).colorScheme.onSurface, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.history,
      title: 'No records for this period',
      message: 'Try a different filter or date range.',
    );
  }

  Widget _buildMilkRecordCard(ShiftMilkEntry record) {
    final muted = context.mutedText;
    final details = <String>[
      '${record.shift} shift',
      if (record.snf != null) 'SNF ${record.snf!.toStringAsFixed(1)}',
      if (record.fatPercentage != null) 'Fat ${record.fatPercentage!.toStringAsFixed(1)}%',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: IconTile(record.shift == 'Morning' ? Icons.wb_twilight_outlined : Icons.nights_stay_outlined),
          title: Text(DateFormat('EEE, MMM d').format(record.entryDate), style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(details.join('  ·  '), style: TextStyle(color: muted, fontSize: 12)),
          trailing: Text(
            '${record.quantity.toStringAsFixed(1)} L',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
        ),
      ),
    );
  }
}

