import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../widgets/stat_card.dart';
import '../widgets/global_drawer.dart';
import '../services/database_service.dart';
import '../services/language_provider.dart';
import '../services/shortcut_provider.dart';
import '../services/weather_service.dart';
import '../services/privacy_provider.dart';
import 'package:home_widget/home_widget.dart';
import 'milk_entry_screen.dart';
import 'cow_list_screen.dart';
import 'payments_expenses_screen.dart';
import 'milk_history_screen.dart';
import 'add_expense_screen.dart';
import 'add_cow_screen.dart';
import 'add_payment_screen.dart';
import 'global_add_breeding_screen.dart';
import 'global_add_health_record_screen.dart';
import 'reports_screen.dart';
import 'farm_calendar_screen.dart';
import 'weather_screen.dart';
import 'sell_cow_screen.dart';
import 'drying_off_screen.dart';
import 'todo_list_screen.dart';
import 'purchase_cow_screen.dart';
import 'shortcut_manager_screen.dart';
import 'alerts_manager_screen.dart';
import '../widgets/global_error_view.dart';
import '../widgets/premium_loading.dart';
import '../models/milk_goal.dart';
import '../services/notification_service.dart';
import 'vet_contacts_screen.dart';
import 'custom_alert_screen.dart';
import 'budget_manager_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onMenuPressed;
  const DashboardScreen({super.key, required this.onMenuPressed});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseService();
  final WeatherService _weatherService = WeatherService();

  int _totalCows = 0;
  double _todayMilk = 0.0;
  double _yesterdayMilk = 0.0;
  double _netProfit = 0.0;
  List<FlSpot> _weeklySpots = [];
  List<String> _chartDates = [];
  List<Map<String, dynamic>> _topAlerts = [];
  List<double> _yearlyIn = [];
  List<double> _yearlyOut = [];
  List<String> _monthLabels = [];
  WeatherData? _weatherData;
  bool _showBarChart = true;
  MilkGoal? _milkGoal;
  double _monthMilkTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadGoal();
    _scheduleDailyDigest();
    _db.autoCreateRecurringExpenses();
  }

  Future<void> _loadGoal() async {
    final now = DateTime.now();
    final goal = await _db.getMilkGoal(now.month, now.year);
    if (mounted) setState(() => _milkGoal = goal);
  }

  void _scheduleDailyDigest() {
    NotificationService.scheduleDailyShiftReminders(
      morningHour: 20, morningMin: 0,
      eveningHour: 20, eveningMin: 0,
    ).catchError((_) {});
  }

  Future<void> _loadWeather() async {
    try {
      final data = await _weatherService.getCurrentWeather();
      if (mounted) setState(() => _weatherData = data);
    } catch (e) {}
  }

  Future<void> _syncHomeWidget() async {
    try {
      await HomeWidget.saveWidgetData<String>('today_milk', _todayMilk.toStringAsFixed(1));
      await HomeWidget.saveWidgetData<String>('total_cows', _totalCows.toString());
      await HomeWidget.saveWidgetData<String>('net_profit', _netProfit.toInt().toString());
      
      final widgetNames = ['DairyWidgetProvider', 'MilkWidgetProvider', 'CowsWidgetProvider', 'ProfitWidgetProvider'];
      for (final name in widgetNames) {
        await HomeWidget.updateWidget(name: name, androidName: name);
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final sp = Provider.of<ShortcutProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: GlobalDrawer(currentIndex: 0, onTabSelected: widget.onMenuPressed),
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Consumer<PrivacyProvider>(
            builder: (context, privacy, child) => IconButton(
              icon: Icon(privacy.hideBalances ? Icons.visibility_off : Icons.visibility, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => privacy.togglePrivacy(),
            ),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _db.getDashboardDataStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return GlobalErrorView(
              error: snapshot.error,
              onRetry: () => setState(() {}),
            );
          }
          if (!snapshot.hasData) {
            return const PremiumLoading(message: 'Updating your farm dashboard...');
          }

          final data = snapshot.data!;
          _totalCows = data['totalCows'];
          _todayMilk = data['todayMilk'];
          _yesterdayMilk = data['yesterdayMilk'];
          _netProfit = data['netProfit'];
          _weeklySpots = data['weeklySpots'];
          _chartDates = data['chartDates'];
          _topAlerts = data['topAlerts'];
          _yearlyIn = data['yearlyIn'];
          _yearlyOut = data['yearlyOut'];
          _monthLabels = data['monthLabels'];

          _syncHomeWidget();

          double milkDiff = _todayMilk - _yesterdayMilk;

          return RefreshIndicator(
            onRefresh: () async {
              await _loadWeather();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.containerPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_weatherData != null) ...[
                    _buildWeatherCard(),
                    const SizedBox(height: 16),
                  ],
                  
                  // Today's Stats
                  Row(
                    children: [
                      Expanded(child: StatCard(label: lp.translate('today_milk'), value: '${_todayMilk.toStringAsFixed(1)}L', icon: Icons.water_drop, color: Colors.blue, subtitle: milkDiff == 0 ? lp.translate('same_as_yesterday') : '${milkDiff > 0 ? "+" : ""}${milkDiff.toStringAsFixed(1)}L ${lp.translate('from_yesterday')}')),
                      const SizedBox(width: 16),
                      Expanded(child: StatCard(label: lp.translate('net_balance'), value: Provider.of<PrivacyProvider>(context).hideBalances ? '₹***' : '₹${_netProfit.toInt()}', icon: Icons.account_balance_wallet, color: _netProfit >= 0 ? Colors.green : Colors.red, subtitle: lp.translate('overall_profit'))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Goal Tracker Ring
                  _buildGoalTracker(lp),
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  _buildQuickActionsHeader(lp),
                  const SizedBox(height: 12),
                  _buildShortcutGrid(lp, sp),
                  const SizedBox(height: 24),

                  // Maternity Alerts
                  if (_topAlerts.isNotEmpty) ...[
                    _buildAlertSection(lp),
                    const SizedBox(height: 24),
                  ],

                  // Analysis Charts
                  _buildLineChartCard(lp),
                  const SizedBox(height: 16),
                  _buildFinancialComparisonCard(lp),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalTracker(dynamic lp) {
    final goal = _milkGoal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80, height: 80,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 80, height: 80, child: CircularProgressIndicator(
                value: goal != null && goal.targetLiters > 0 ? (_todayMilk / goal.targetLiters * 30).clamp(0.0, 1.0) : 0,
                strokeWidth: 8, backgroundColor: Theme.of(context).dividerColor,
                valueColor: AlwaysStoppedAnimation(goal != null ? AppConstants.primaryColor : Colors.grey.shade300),
              )),
              Text(goal != null && goal.targetLiters > 0 ? '${((_todayMilk / goal.targetLiters * 30) * 100).clamp(0, 999).toInt()}%' : '—',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: goal != null ? AppConstants.primaryColor : Colors.grey)),
            ]),
          ),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🎯 Monthly Milk Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            if (goal != null) Text('${_todayMilk.toStringAsFixed(1)}L today • Target: ${goal.targetLiters.toStringAsFixed(0)}L/month', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))
            else Text('Tap to set a production goal', style: TextStyle(fontSize: 12, color: Theme.of(context).cardColor)),
          ])),
          IconButton(icon: Icon(goal != null ? Icons.edit : Icons.add_circle_outline, color: AppConstants.primaryColor), onPressed: _showGoalDialog),
        ],
      ),
    );
  }

  void _showGoalDialog() {
    final ctrl = TextEditingController(text: _milkGoal?.targetLiters.toStringAsFixed(0) ?? '');
    final now = DateTime.now();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Set Goal — ${DateFormat('MMMM').format(now)}'),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number, autofocus: true, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        decoration: InputDecoration(suffixText: 'Liters', hintText: 'e.g. 500', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          if (ctrl.text.isEmpty) return;
          await _db.upsertMilkGoal(MilkGoal(id: '', targetLiters: double.parse(ctrl.text), month: now.month, year: now.year));
          if (mounted) { Navigator.pop(ctx); _loadGoal(); }
        }, style: FilledButton.styleFrom(backgroundColor: AppConstants.primaryColor), child: const Text('Save')),
      ],
    ));
  }

  Widget _buildWeatherCard() {
    final w = _weatherData!;
    final isHeat = w.isHeatStress;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isHeat ? [Colors.orange.shade600, Colors.red.shade400] : [AppConstants.primaryColor, Colors.teal.shade700],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.locationName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('${w.temperature.toStringAsFixed(1)}°C', style: TextStyle(color: Theme.of(context).cardColor, fontSize: 32, fontWeight: FontWeight.bold)),
                  Text(w.condition, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              Text(w.icon, style: const TextStyle(fontSize: 48)),
            ],
          ),
          if (isHeat) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Text('⚠️ Heat Stress: ${w.heatStressLevel}', style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialComparisonCard(LanguageProvider lp) {
    double currentIn = _yearlyIn.isNotEmpty ? _yearlyIn.last : 0;
    double currentOut = _yearlyOut.isNotEmpty ? _yearlyOut.last : 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lp.isTamil ? 'நிதி நிலை (12 மாதங்கள்)' : 'Financials (Last 12 Months)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              IconButton(
                icon: Icon(_showBarChart ? Icons.show_chart : Icons.bar_chart, size: 20, color: AppConstants.primaryColor),
                onPressed: () => setState(() => _showBarChart = !_showBarChart),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: _showBarChart ? _buildBarChartView() : _buildLineChartView(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendItem(lp.translate('income'), Colors.teal),
              _legendItem(lp.translate('expense'), Colors.red),
              Text('NET: ${Provider.of<PrivacyProvider>(context).hideBalances ? "₹***" : "₹${(currentIn - currentOut).toInt()}"}', style: TextStyle(fontWeight: FontWeight.w900, color: (currentIn >= currentOut) ? Colors.teal : Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBarChartView() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxVal() * 1.2,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) => Text(_monthLabels[val.toInt()], style: const TextStyle(fontSize: 8, color: Colors.grey)))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(12, (i) => BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: _yearlyIn[i], color: Colors.teal, width: 6),
            BarChartRodData(toY: _yearlyOut[i], color: Colors.red, width: 6),
          ],
        )),
      ),
    );
  }

  Widget _buildLineChartView() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) => Text(_monthLabels[val.toInt()], style: const TextStyle(fontSize: 8, color: Colors.grey)))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(12, (i) => FlSpot(i.toDouble(), _yearlyIn[i])),
            color: Colors.teal, isCurved: true, barWidth: 3, dotData: FlDotData(show: false),
          ),
          LineChartBarData(
            spots: List.generate(12, (i) => FlSpot(i.toDouble(), _yearlyOut[i])),
            color: Colors.red, isCurved: true, barWidth: 3, dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  double _getMaxVal() {
    double m1 = _yearlyIn.fold(0, (max, v) => v > max ? v : max);
    double m2 = _yearlyOut.fold(0, (max, v) => v > max ? v : max);
    return m1 > m2 ? m1 : m2;
  }

  Widget _buildAlertSection(LanguageProvider lp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [const Icon(Icons.stars, color: Colors.orange, size: 18), const SizedBox(width: 8), Text(lp.isTamil ? 'பேறுகால அறிவிப்புகள்' : 'Maternity Status', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13))]),
        const SizedBox(height: 12), _buildAlertStrip(lp),
      ],
    );
  }

  Widget _buildAlertStrip(LanguageProvider lp) {
    return SizedBox(height: 60, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _topAlerts.length, itemBuilder: (context, index) {
      final alert = _topAlerts[index];
      final daysLeft = alert['date'].difference(DateTime.now()).inDays;
      final bool isUrgent = daysLeft <= 15;
      return Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: isUrgent ? Colors.red.shade50 : Colors.teal.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: isUrgent ? Colors.red.shade100 : Colors.teal.shade100)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text('${alert['tag']} predicted delivery:', style: TextStyle(fontSize: 10, color: isUrgent ? Colors.red.shade700 : Colors.teal.shade800)), Text('${DateFormat('MMM d').format(alert['date'])} ($daysLeft days left)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isUrgent ? Colors.red.shade900 : Colors.teal.shade900))]));
    }));
  }

  Widget _buildLineChartCard(LanguageProvider lp) {
    double minY = 0;
    double maxY = 20; // fallback
    if (_weeklySpots.isNotEmpty) {
      minY = _weeklySpots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
      maxY = _weeklySpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      minY = (minY - 5).floorToDouble().clamp(0, double.infinity);
      maxY = (maxY + 5).ceilToDouble();
    }

    return Container(padding: const EdgeInsets.fromLTRB(16, 20, 16, 12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(lp.isTamil ? 'வாராந்திர விளைச்சல்' : 'Weekly Yield Trend (L)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Icon(Icons.trending_up, color: Colors.green.shade400, size: 20)]),
      const SizedBox(height: 32),
      SizedBox(height: 140, child: LineChart(LineChartData(
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppConstants.primaryColor,
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(s.y.toStringAsFixed(1), TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold, fontSize: 12))).toList(),
          ),
        ),
        gridData: FlGridData(show: false), 
        titlesData: FlTitlesData(
          show: true, 
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), 
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), 
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, 
            interval: 1,
            getTitlesWidget: (value, meta) { 
              if (value < 0 || value >= _chartDates.length) return const Text(''); 
              final date = DateTime.parse(_chartDates[value.toInt()]); 
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(DateFormat('E').format(date), style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ); 
            }
          )), 
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, 
            reservedSize: 30, 
            interval: ((maxY - minY) / 3).clamp(1, double.infinity),
            getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 10))
          ))
        ), 
        borderData: FlBorderData(show: false), 
        lineBarsData: [
          LineChartBarData(
            spots: _weeklySpots, 
            isCurved: true, 
            gradient: const LinearGradient(colors: [AppConstants.primaryColor, Colors.teal]), 
            barWidth: 4, 
            dotData: FlDotData(show: true), 
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppConstants.primaryColor.withOpacity(0.2), AppConstants.primaryColor.withOpacity(0.0)]))
          )
        ]
      ))),
    ]));
  }

  Widget _buildQuickActionsHeader(LanguageProvider lp) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(lp.translate('quick_actions'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), IconButton(icon: const Icon(Icons.settings_outlined, size: 20), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShortcutManagerScreen()))),]);
  }

  Widget _buildShortcutGrid(LanguageProvider lp, ShortcutProvider sp) {
    if (sp.selectedShortcuts.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('Add shortcuts in settings', style: TextStyle(color: Colors.grey, fontSize: 12))));
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.6), itemCount: sp.selectedShortcuts.length, itemBuilder: (context, index) { 
      final key = sp.selectedShortcuts[index]; 
      final data = Map<String, dynamic>.from(ShortcutProvider.allShortcuts[key]!); 
      String label = lp.translate(key);
      
      // Smart Detection for Milk Entry
      if (key == 'add_milk') {
        final hour = DateTime.now().hour;
        final isMorning = hour >= 19 || hour < 7;
        label = isMorning ? (lp.isTamil ? 'காலை பால் பதிவு' : 'Morning Milk') : (lp.isTamil ? 'மாலை பால் பதிவு' : 'Evening Milk');
      }
      
      return _buildQuickAction(label, data['icon'] as IconData, data['color'] as Color, () => _navigate(key)); 
    });
  }

  void _navigate(String key) {
    HapticFeedback.selectionClick();
    Widget target;
    switch (key) {
      case 'cow_list': target = CowListScreen(onMenuPressed: widget.onMenuPressed); break;
      case 'milk_history': target = MilkHistoryScreen(onMenuPressed: widget.onMenuPressed); break;
      case 'financials': target = PaymentsExpensesScreen(onMenuPressed: widget.onMenuPressed); break;
      case 'alerts': target = AlertsManagerScreen(onMenuPressed: widget.onMenuPressed); break;
      case 'add_milk': target = const MilkEntryScreen(); break;
      case 'add_expense': target = const AddExpenseScreen(); break;
      case 'add_cow': target = const AddCowScreen(); break;
      case 'add_payment': target = const AddPaymentScreen(); break;
      case 'breeding_inj': target = const GlobalAddBreedingScreen(); break;
      case 'add_health_record': target = const GlobalAddHealthRecordScreen(); break;
      case 'export_reports': target = const ReportsScreen(); break;
      case 'farm_calendar': target = const FarmCalendarScreen(); break;
      case 'weather_forecast': target = const WeatherScreen(); break;
      case 'sell_cow': target = const SellCowScreen(); break;
      case 'dry_cow': target = const DryingOffScreen(); break;
      case 'todo_list': target = const TodoListScreen(); break;
      case 'purchase_cow': target = const PurchaseCowScreen(); break;
      case 'vet_contacts': target = const VetContactsScreen(); break;
      case 'custom_reminders': target = const CustomAlertScreen(); break;
      case 'budget_manager': target = const BudgetManagerScreen(); break;
      default: return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => target));
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
