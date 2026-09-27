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
import '../widgets/app_ui.dart';
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
          unselectedLabelColor: context.mutedText,
          indicatorColor: AppConstants.primaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Payments received'),
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
          if (!snapshot.hasData) return const PremiumLoading(message: 'Loading financials…');

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
              _buildHistorySection(_payments, 'Payments', _getTotalPayments, AppConstants.successColor),
              _buildHistorySection(_expenses, 'Expenses', _getTotalExpenses, AppConstants.dangerColor),
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
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Add payment' : 'Add expense'),
      ),
    );
  }

  Widget _buildSummaryCard(String title, Function() totalGetter) {
    final hide = Provider.of<PrivacyProvider>(context).hideBalances;
    final paymentsTotal = _getTotalPayments();
    final expensesTotal = _getTotalExpenses();
    final netProfit = paymentsTotal - expensesTotal;
    final isProfit = netProfit >= 0;
    final isLifetime = _filter == FinancialFilter.lifetime;
    final isPaymentTab = title == 'Payments';

    Widget metric(String label, String value, Color valueColor) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: context.mutedText, fontSize: 12)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: TextStyle(color: valueColor, fontSize: 22, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: AppCard(
        child: IntrinsicHeight(
          child: Row(
            children: [
              metric(
                isLifetime ? 'Net profit · lifetime' : 'Net profit · this month',
                hide ? '₹***' : '${isProfit ? "+" : "-"}₹${netProfit.toInt().abs()}',
                isProfit ? AppConstants.successColor : AppConstants.dangerColor,
              ),
              VerticalDivider(width: 24, color: Theme.of(context).dividerColor),
              metric(
                isLifetime
                    ? (isPaymentTab ? 'Total payments' : 'Total expenses')
                    : (isPaymentTab ? 'Payments this month' : 'Expenses this month'),
                hide ? '₹***' : '₹${totalGetter().toInt()}',
                Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection(List<dynamic> items, String title, Function() totalGetter, Color color) {
    final hide = Provider.of<PrivacyProvider>(context).hideBalances;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSummaryCard(title, totalGetter)),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No ${title.toLowerCase()} yet',
                  message: 'Records you add will appear here.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      final isPayment = item is Payment;
                      final date = isPayment ? item.paymentDate : item.expenseDate;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            onTap: () {
                              if (isPayment) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentDetailScreen(payment: item)));
                              } else {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expense: item)));
                              }
                            },
                            leading: IconTile(isPayment ? Icons.south_west : Icons.north_east, color: color, size: 36),
                            title: Text(isPayment ? item.title : (item.title.isNotEmpty ? item.title : item.category),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            subtitle: Text(
                              isPayment ? DateFormat('MMM d, yyyy').format(date) : '${item.category} · ${DateFormat('MMM d, yyyy').format(date)}',
                              style: TextStyle(color: context.mutedText, fontSize: 12),
                            ),
                            trailing: Text(
                              hide ? '₹***' : '${isPayment ? "+" : "-"}₹${item.amount.toInt()}',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

