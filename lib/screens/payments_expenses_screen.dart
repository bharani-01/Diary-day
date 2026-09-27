import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/database_service.dart';
import '../models/payment.dart';
import '../models/expense.dart';
import 'add_payment_screen.dart';
import 'add_expense_screen.dart';
import '../widgets/global_drawer.dart';
import '../widgets/global_error_view.dart';
import 'payment_detail_screen.dart';
import 'expense_detail_screen.dart';
import '../widgets/premium_loading.dart';
import 'package:provider/provider.dart';
import '../services/privacy_provider.dart';

class PaymentsExpensesScreen extends StatefulWidget {
  final Function(int) onMenuPressed;
  const PaymentsExpensesScreen({super.key, required this.onMenuPressed});

  @override
  State<PaymentsExpensesScreen> createState() => _PaymentsExpensesScreenState();
}

enum FinancialFilter { month, lifetime }
enum FinancialSort { date, amount, name }

class _PaymentsExpensesScreenState extends State<PaymentsExpensesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService();
  
  FinancialFilter _filter = FinancialFilter.month;
  FinancialSort _sortBy = FinancialSort.date;
  bool _isAscending = false;

  List<Payment> _payments = [];
  List<Expense> _expenses = [];
  
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.selectionClick();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _getTotalPayments() {
    return _payments.fold(0, (sum, p) => sum + p.amount);
  }

  double _getTotalExpenses() {
    return _expenses.fold(0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: GlobalDrawer(currentIndex: 3, onTabSelected: widget.onMenuPressed),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Filter by Vendor/Name...', border: InputBorder.none),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : const Text('Financials'),
        
        elevation: 0,
        
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
          Consumer<PrivacyProvider>(
            builder: (context, privacy, child) => IconButton(
              icon: Icon(privacy.hideBalances ? Icons.visibility_off : Icons.visibility),
              onPressed: () => privacy.togglePrivacy(),
            ),
          ),
          PopupMenuButton<FinancialFilter>(
            icon: const Icon(Icons.calendar_today_outlined),
            onSelected: (FinancialFilter value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: FinancialFilter.month, child: Text('Last 1 Month')),
              const PopupMenuItem(value: FinancialFilter.lifetime, child: Text('Lifetime History')),
            ],
          ),
          PopupMenuButton<FinancialSort>(
            icon: const Icon(Icons.sort),
            onSelected: (FinancialSort value) {
              if (_sortBy == value) {
                setState(() => _isAscending = !_isAscending);
              } else {
                setState(() {
                  _sortBy = value;
                  _isAscending = false;
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: FinancialSort.date,
                child: Row(
                  children: [
                    const Text('Sort by Date'),
                    if (_sortBy == FinancialSort.date) Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                  ],
                ),
              ),
              PopupMenuItem(
                value: FinancialSort.amount,
                child: Row(
                  children: [
                    const Text('Sort by Amount'),
                    if (_sortBy == FinancialSort.amount) Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                  ],
                ),
              ),
              PopupMenuItem(
                value: FinancialSort.name,
                child: Row(
                  children: [
                    const Text('Sort by Name'),
                    if (_sortBy == FinancialSort.name) Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppConstants.primaryColor,
          tabs: const [
            Tab(text: 'Payments Received'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _db.getFinancialsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return GlobalErrorView(
              error: snapshot.error,
              onRetry: () => setState(() {}),
            );
          }
          if (!snapshot.hasData) return const PremiumLoading(message: 'Analyzing financials...');

          final now = DateTime.now();
          final allPayments = snapshot.data!['payments'] as List<Payment>;
          final allExpenses = snapshot.data!['expenses'] as List<Expense>;

          // Filter
          if (_filter == FinancialFilter.month) {
            _payments = allPayments.where((p) => p.paymentDate.month == now.month && p.paymentDate.year == now.year).toList();
            _expenses = allExpenses.where((e) => e.expenseDate.month == now.month && e.expenseDate.year == now.year).toList();
          } else {
            _payments = List.from(allPayments);
            _expenses = List.from(allExpenses);
          }

          // Search Filter
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            _payments = _payments.where((p) => p.title.toLowerCase().contains(query)).toList();
            _expenses = _expenses.where((e) => e.title.toLowerCase().contains(query) || e.category.toLowerCase().contains(query)).toList();
          }

          // Sort Payments
          _payments.sort((a, b) {
            int cmp;
            switch (_sortBy) {
              case FinancialSort.date:
                cmp = a.paymentDate.compareTo(b.paymentDate);
                break;
              case FinancialSort.amount:
                cmp = a.amount.compareTo(b.amount);
                break;
              case FinancialSort.name:
                cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
                break;
            }
            return _isAscending ? cmp : -cmp;
          });

          // Sort Expenses
          _expenses.sort((a, b) {
            int cmp;
            switch (_sortBy) {
              case FinancialSort.date:
                cmp = a.expenseDate.compareTo(b.expenseDate);
                break;
              case FinancialSort.amount:
                cmp = a.amount.compareTo(b.amount);
                break;
              case FinancialSort.name:
                final aName = a.title.isNotEmpty ? a.title : a.category;
                final bName = b.title.isNotEmpty ? b.title : b.category;
                cmp = aName.toLowerCase().compareTo(bName.toLowerCase());
                break;
            }
            return _isAscending ? cmp : -cmp;
          });

          return TabBarView(
            controller: _tabController,
            children: [
              Column(
                children: [
                  _buildProfitCard(),
                  _buildHistorySection(_payments, 'Payments', _getTotalPayments, Colors.teal),
                ],
              ),
              Column(
                children: [
                  _buildProfitCard(),
                  _buildHistorySection(_expenses, 'Expenses', _getTotalExpenses, Colors.red),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _tabController.index == 0 ? const AddPaymentScreen() : const AddExpenseScreen(),
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(_tabController.index == 0 ? 'Add Payment' : 'Add Expense', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildProfitCard() {
    final paymentsTotal = _getTotalPayments();
    final expensesTotal = _getTotalExpenses();
    final netProfit = paymentsTotal - expensesTotal;
    final isProfit = netProfit >= 0;
    final isLifetime = _filter == FinancialFilter.lifetime;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isProfit 
              ? [const Color(0xFF00796B), const Color(0xFF00897B)]
              : [Colors.red.shade800, Colors.red.shade500],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: (isProfit ? Colors.teal : Colors.red).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLifetime ? 'LIFETIME NET PROFIT' : 'MONTHLY NET PROFIT', 
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)
              ),
              const SizedBox(height: 12),
              Text(
                Provider.of<PrivacyProvider>(context).hideBalances ? '₹***' : '${isProfit ? "+" : "-"}₹${netProfit.toInt().abs()}',
                style: TextStyle(color: Theme.of(context).cardColor, fontSize: 36, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Icon(isProfit ? Icons.trending_up : Icons.trending_down, color: Theme.of(context).cardColor, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(List<dynamic> items, String title, Function() totalGetter, Color color) {
    bool isPaymentTab = title == 'Payments';
    final isLifetime = _filter == FinancialFilter.lifetime;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card for Total
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLifetime 
                    ? (isPaymentTab ? 'Total Payments' : 'Total Expenses')
                    : (isPaymentTab ? 'Payments this month' : 'Expenses this month'),
                  style: TextStyle(color: color.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  Provider.of<PrivacyProvider>(context).hideBalances ? '₹***' : '₹${totalGetter().toInt()}',
                  style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text('No $title records yet.', style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isPayment = item is Payment;
                      final date = isPayment ? item.paymentDate : item.expenseDate;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () {
                            if (isPayment) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentDetailScreen(payment: item)));
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expense: item)));
                            }
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            child: Icon(Icons.currency_rupee, color: Theme.of(context).cardColor, size: 16),
                          ),
                          title: Text(isPayment ? item.title : (item.title.isNotEmpty ? item.title : item.category), 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text(DateFormat('MMM d, yyyy').format(date), style: TextStyle(color: Theme.of(context).cardColor, fontSize: 12)),
                          trailing: Text(
                            Provider.of<PrivacyProvider>(context).hideBalances ? '₹***' : '${isPayment ? "+" : "-"}₹${item.amount.toInt()}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
