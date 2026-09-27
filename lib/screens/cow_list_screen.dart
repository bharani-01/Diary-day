import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../services/database_service.dart';
import '../models/cow.dart';
import 'add_cow_screen.dart';
import 'cow_detail_screen.dart';
import '../widgets/global_drawer.dart';
import '../widgets/global_error_view.dart';
import '../widgets/cow_image.dart';

class CowListScreen extends StatefulWidget {
  final Function(int) onMenuPressed;
  const CowListScreen({super.key, required this.onMenuPressed});

  @override
  State<CowListScreen> createState() => _CowListScreenState();
}

class _CowListScreenState extends State<CowListScreen> {
  final _db = DatabaseService();
  late Stream<List<Cow>> _cowsStream;
  List<Cow> _allCows = [];
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cowsStream = _db.getCowsStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter(String filter) {
    HapticFeedback.selectionClick();
    setState(() => _selectedFilter = filter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: GlobalDrawer(currentIndex: 2, onTabSelected: widget.onMenuPressed),
      appBar: AppBar(
        title: const Text('My Herd'),
        
        elevation: 0,
        
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search tag number or name...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    })
                  : null,
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<Cow>>(
              stream: _cowsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return GlobalErrorView(
                    error: snapshot.error,
                    isFullScreen: false,
                    onRetry: () => setState(() => _cowsStream = _db.getCowsStream()),
                  );
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                _allCows = snapshot.data!;
                List<Cow> filtered = _allCows;
                if (_selectedFilter == 'Healthy') {
                  filtered = _allCows.where((c) => c.healthStatus == 'Healthy').toList();
                } else if (_selectedFilter == 'Issues') {
                  filtered = _allCows.where((c) => c.healthStatus != 'Healthy').toList();
                } else if (_selectedFilter == 'Buffalo') {
                  filtered = _allCows.where((c) => c.cowType == 'Buffalo').toList();
                } else if (_selectedFilter == 'Cow') {
                  filtered = _allCows.where((c) => c.dynamicCowType == 'Cow').toList();
                } else if (_selectedFilter == 'Calf') {
                  filtered = _allCows.where((c) => c.dynamicCowType == 'Calf').toList();
                } else if (_selectedFilter == 'Heifer') {
                  filtered = _allCows.where((c) => c.dynamicCowType == 'Heifer').toList();
                } else if (_selectedFilter == 'Bull') {
                  filtered = _allCows.where((c) => c.dynamicCowType == 'Bull').toList();
                }

                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.trim().toLowerCase();
                  filtered = filtered.where((c) => 
                    c.tagNumber.toLowerCase().contains(query) || 
                    (c.name?.toLowerCase().contains(query) ?? false)
                  ).toList();
                }

                if (filtered.isEmpty) return _buildEmptyState();

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final cow = filtered[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CowDetailScreen(cow: cow))),
                      child: _buildCowCard(cow),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCowScreen())),
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: ['All', 'Healthy', 'Issues', 'Cow', 'Buffalo', 'Calf', 'Heifer', 'Bull'].map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => _applyFilter(filter),
              selectedColor: AppConstants.primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(color: isSelected ? AppConstants.primaryColor : Theme.of(context).colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
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
          Icon(Icons.pets, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(_allCows.isEmpty ? 'No cows registered yet.' : 'No cows match this filter.', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCowCard(Cow cow) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CowImage(url: cow.imageUrl, width: double.infinity),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cow.name != null ? '${cow.tagNumber} (${cow.name})' : cow.tagNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${cow.dynamicCowType} • ${cow.breed ?? 'Native'}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 2),
                Text('Age: ${cow.formattedAge}', style: TextStyle(fontSize: 11, color: Colors.indigo.shade600, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cow.healthStatus == 'Healthy' ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    cow.healthStatus,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cow.healthStatus == 'Healthy' ? Colors.green : Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
