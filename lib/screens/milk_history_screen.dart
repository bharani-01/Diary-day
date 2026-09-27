import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants.dart';
import '../services/database_service.dart';
import '../models/shift_milk_entry.dart';
import '../widgets/error_dialog.dart';
import '../widgets/global_drawer.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: GlobalDrawer(currentIndex: 1, onTabSelected: widget.onMenuPressed),
      appBar: AppBar(
        title: const Text('Milk History & Trends'),
        
        elevation: 0,
        
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort Records',
            onSelected: (SortOption result) {
              setState(() => _selectedSort = result);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              const PopupMenuItem<SortOption>(value: SortOption.dateDesc, child: Text('Date (Newest First)')),
              const PopupMenuItem<SortOption>(value: SortOption.dateAsc, child: Text('Date (Oldest First)')),
              const PopupMenuDivider(),
              const PopupMenuItem<SortOption>(value: SortOption.litersDesc, child: Text('Liters (High to Low)')),
              const PopupMenuItem<SortOption>(value: SortOption.litersAsc, child: Text('Liters (Low to High)')),
              const PopupMenuDivider(),
              const PopupMenuItem<SortOption>(value: SortOption.fatDesc, child: Text('Fat % (High to Low)')),
              const PopupMenuItem<SortOption>(value: SortOption.fatAsc, child: Text('Fat % (Low to High)')),
              const PopupMenuDivider(),
              const PopupMenuItem<SortOption>(value: SortOption.snfDesc, child: Text('SNF (High to Low)')),
              const PopupMenuItem<SortOption>(value: SortOption.snfAsc, child: Text('SNF (Low to High)')),
            ],
          ),
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickDateRange, tooltip: 'Search Date Range'),
        ],
      ),
      body: StreamBuilder<List<ShiftMilkEntry>>(
        stream: _db.getShiftMilkEntriesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          _allRecords = snapshot.data!;
          _filterRecords();

          return Column(
            children: [
              _buildStatsHeader(),
              _buildYieldComparisonChart(),
              _buildFilterChips(),
              Expanded(
                child: _filteredRecords.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = _filteredRecords[index];
                          return _buildMilkRecordCard(record);
                        },
                      ),
              ),
            ],
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
    
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConstants.primaryColor, Color(0xFF00897B)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppConstants.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Total Liters', total.toStringAsFixed(1), 'L'),
              _statItem('Entries', _filteredRecords.length.toString(), ''),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white24),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('30D Avg SNF', avgSnf30.toStringAsFixed(2), ''),
              _statItem('30D Avg Fat', avgFat30.toStringAsFixed(2), '%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(color: Theme.of(context).cardColor, fontSize: 20, fontWeight: FontWeight.bold)),
            if (unit.isNotEmpty) Text(' $unit', style: TextStyle(color: Theme.of(context).cardColor, fontSize: 10)),
          ],
        ),
      ],
    );
  }

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
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('☀️ vs 🌙 Yield Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              const Text('Morning', style: TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(width: 8),
              Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              const Text('Evening', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9, color: Colors.grey)))),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 7, getTitlesWidget: (v, _) {
                  final date = now.subtract(Duration(days: days - 1 - v.toInt()));
                  return Padding(padding: const EdgeInsets.only(top: 4), child: Text(DateFormat('d/M').format(date), style: const TextStyle(fontSize: 8, color: Colors.grey)));
                })),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(spots: morningSpots, color: Colors.orange, barWidth: 2.5, dotData: FlDotData(show: false), belowBarData: BarAreaData(show: true, color: Colors.orange.withOpacity(0.08))),
                LineChartBarData(spots: eveningSpots, color: Colors.indigo, barWidth: 2.5, dotData: FlDotData(show: false), belowBarData: BarAreaData(show: true, color: Colors.indigo.withOpacity(0.08))),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
              selectedColor: AppConstants.primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(color: isSelected ? AppConstants.primaryColor : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No records found for this period.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMilkRecordCard(ShiftMilkEntry record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: record.shift == 'Morning' ? Colors.orange.shade50 : Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            record.shift == 'Morning' ? Icons.wb_sunny : Icons.nightlight_round,
            color: record.shift == 'Morning' ? Colors.orange : Colors.indigo,
          ),
        ),
        title: Text(DateFormat('EEEE, MMM d').format(record.entryDate), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text('${record.shift} Shift', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
              const SizedBox(width: 8),
              if (record.snf != null) ...[
                Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('SNF: ${record.snf!.toStringAsFixed(1)}', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
              if (record.fatPercentage != null) ...[
                const SizedBox(width: 8),
                Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('Fat: ${record.fatPercentage!.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ],
          ),
        ),
        trailing: Text(
          '${record.quantity.toStringAsFixed(1)}L',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppConstants.primaryColor),
        ),
      ),
    );
  }
}
