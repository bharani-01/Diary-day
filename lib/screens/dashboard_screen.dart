import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../widgets/app_ui.dart';
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
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        centerTitle: false,
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
            return const PremiumLoading(message: 'Loading dashboard…');
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
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Today's Stats
                      Row(
                        children: [
                          Expanded(child: StatCard(label: lp.translate('today_milk'), value: '${_todayMilk.toStringAsFixed(1)} L', icon: Icons.water_drop_outlined, subtitle: milkDiff == 0 ? lp.translate('same_as_yesterday') : '${milkDiff > 0 ? "+" : ""}${milkDiff.toStringAsFixed(1)} L ${lp.translate('from_yesterday')}')),
                          const SizedBox(width: 12),
                          Expanded(child: StatCard(label: lp.translate('net_balance'), value: Provider.of<PrivacyProvider>(context).hideBalances ? '₹***' : '₹${_netProfit.toInt()}', icon: Icons.account_balance_wallet_outlined, color: _netProfit >= 0 ? AppConstants.successColor : AppConstants.dangerColor, subtitle: lp.translate('overall_profit'))),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_weatherData != null) ...[
                        _buildWeatherCard(),
                        const SizedBox(height: 12),
                      ],

                      // Goal Tracker Ring
                      _buildGoalTracker(lp),
                      const SizedBox(height: AppConstants.sectionGap),
                      
                      // Quick Actions
                      _buildQuickActionsHeader(lp),
                      _buildShortcutGrid(lp, sp),
                      const SizedBox(height: AppConstants.sectionGap),

                      // Maternity Alerts
                      if (_topAlerts.isNotEmpty) ...[
                        _buildAlertSection(lp),
                        const SizedBox(height: AppConstants.sectionGap),
                      ],

                      // Analysis Charts
                      _buildLineChartCard(lp),
                      const SizedBox(height: 12),
                      _buildFinancialComparisonCard(lp),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalTracker(dynamic lp) {
    final goal = _milkGoal;
    final hasGoal = goal != null && goal.targetLiters > 0;
    return AppCard(
      onTap: _showGoalDialog,
      child: Row(
        children: [
          SizedBox(
            width: 56, height: 56,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 56, height: 56, child: CircularProgressIndicator(
                value: hasGoal ? (_todayMilk / goal.targetLiters * 30).clamp(0.0, 1.0) : 0,
                strokeWidth: 5, backgroundColor: Theme.of(context).dividerColor,
                valueColor: const AlwaysStoppedAnimation(AppConstants.primaryColor),
              )),
              Text(hasGoal ? '${((_todayMilk / goal.targetLiters * 30) * 100).clamp(0, 999).toInt()}%' : '—',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: hasGoal ? Theme.of(context).colorScheme.onSurface : context.mutedText)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Monthly milk goal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            if (goal != null) Text('${_todayMilk.toStringAsFixed(1)} L today · Target ${goal.targetLiters.toStringAsFixed(0)} L / month', style: TextStyle(fontSize: 13, color: context.mutedText))
            else Text('Set a production target for this month', style: TextStyle(fontSize: 13, color: context.mutedText)),
          ])),
          IconButton(
            tooltip: goal != null ? 'Edit goal' : 'Set goal',
            icon: Icon(goal != null ? Icons.edit_outlined : Icons.add, color: context.mutedText, size: 20),
            onPressed: _showGoalDialog,
          ),
        ],
      ),
    );
  }

  void _showGoalDialog() {
    final ctrl = TextEditingController(text: _milkGoal?.targetLiters.toStringAsFixed(0) ?? '');
    final now = DateTime.now();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Milk goal — ${DateFormat('MMMM').format(now)}'),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number, autofocus: true, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        decoration: AppConstants.inputDecoration('Monthly target', ctx).copyWith(suffixText: 'litres', hintText: 'e.g. 500')),
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
    final heatColor = w.temperature >= 35 ? AppConstants.dangerColor : AppConstants.warningColor;
    return AppCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherScreen())),
      child: Row(
        children: [
          IconTile(weatherIcon(w.weatherCode), size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.locationName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: context.mutedText)),
                const SizedBox(height: 2),
                Text('${w.temperature.toStringAsFixed(1)}°C · ${w.condition}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (isHeat)
            StatusPill(label: 'Heat stress: ${w.heatStressLevel}', color: heatColor, icon: Icons.warning_amber_rounded),
        ],
      ),
    );
  }

  Widget _buildFinancialComparisonCard(LanguageProvider lp) {
    double currentIn = _yearlyIn.isNotEmpty ? _yearlyIn.last : 0;
    double currentOut = _yearlyOut.isNotEmpty ? _yearlyOut.last : 0;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(lp.isTamil ? 'நிதி நிலை (12 மாதங்கள்)' : 'Income vs expenses · 12 months', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
              IconButton(
                tooltip: _showBarChart ? 'Show line chart' : 'Show bar chart',
                icon: Icon(_showBarChart ? Icons.show_chart : Icons.bar_chart, size: 20, color: context.mutedText),
                onPressed: () => setState(() => _showBarChart = !_showBarChart),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              height: 180,
              child: _showBarChart ? _buildBarChartView() : _buildLineChartView(),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                _legendItem(lp.translate('income'), AppConstants.primaryColor),
                const SizedBox(width: 16),
                _legendItem(lp.translate('expense'), AppConstants.dangerColor),
                const Spacer(),
                Text('This month  ', style: TextStyle(fontSize: 12, color: context.mutedText)),
                Text(Provider.of<PrivacyProvider>(context).hideBalances ? '₹***' : '₹${(currentIn - currentOut).toInt()}', style: TextStyle(fontWeight: FontWeight.w700, color: (currentIn >= currentOut) ? AppConstants.successColor : AppConstants.dangerColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: context.mutedText)),
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
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) => Padding(padding: const EdgeInsets.only(top: 4), child: Text(_monthLabels[val.toInt()], style: TextStyle(fontSize: 9, color: context.mutedText))))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(12, (i) => BarChartGroupData(
          x: i,
          barsSpace: 2,
          barRods: [
            BarChartRodData(toY: _yearlyIn[i], color: AppConstants.primaryColor, width: 5, borderRadius: BorderRadius.circular(1)),
            BarChartRodData(toY: _yearlyOut[i], color: AppConstants.dangerColor.withOpacity(0.75), width: 5, borderRadius: BorderRadius.circular(1)),
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
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) => Padding(padding: const EdgeInsets.only(top: 4), child: Text(_monthLabels[val.toInt()], style: TextStyle(fontSize: 9, color: context.mutedText))))),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(12, (i) => FlSpot(i.toDouble(), _yearlyIn[i])),
            color: AppConstants.primaryColor, isCurved: false, barWidth: 2, dotData: FlDotData(show: false),
          ),
          LineChartBarData(
            spots: List.generate(12, (i) => FlSpot(i.toDouble(), _yearlyOut[i])),
            color: AppConstants.dangerColor, isCurved: false, barWidth: 2, dotData: FlDotData(show: false),
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
        SectionHeader(lp.isTamil ? 'பேறுகால அறிவிப்புகள்' : 'Upcoming calvings'),
        _buildAlertStrip(lp),
      ],
    );
  }

  Widget _buildAlertStrip(LanguageProvider lp) {
    return SizedBox(height: 64, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _topAlerts.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (context, index) {
      final alert = _topAlerts[index];
      final daysLeft = alert['date'].difference(DateTime.now()).inDays;
      final bool isUrgent = daysLeft <= 15;
      final accent = isUrgent ? AppConstants.dangerColor : Theme.of(context).colorScheme.onSurface;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUrgent ? AppConstants.dangerColor.withOpacity(0.06) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: isUrgent ? AppConstants.dangerColor.withOpacity(0.3) : Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${alert['tag']} · due ${DateFormat('MMM d').format(alert['date'])}', style: TextStyle(fontSize: 12, color: context.mutedText)),
            const SizedBox(height: 2),
            Text('$daysLeft days left', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: accent)),
          ],
        ),
      );
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

    return AppCard(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(lp.isTamil ? 'வாராந்திர விளைச்சல்' : 'Milk yield · last 7 days (L)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      const SizedBox(height: 20),
      SizedBox(height: 140, child: LineChart(LineChartData(
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppConstants.primaryColor,
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem('${s.y.toStringAsFixed(1)} L', const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))).toList(),
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
                child: Text(DateFormat('E').format(date), style: TextStyle(color: context.mutedText, fontSize: 10)),
              ); 
            }
          )), 
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, 
            reservedSize: 30, 
            interval: ((maxY - minY) / 3).clamp(1, double.infinity),
            getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(color: context.mutedText, fontSize: 10))
          ))
        ), 
        borderData: FlBorderData(show: false), 
        lineBarsData: [
          LineChartBarData(
            spots: _weeklySpots, 
            isCurved: false, 
            color: AppConstants.primaryColor, 
            barWidth: 2, 
            dotData: FlDotData(show: true), 
            belowBarData: BarAreaData(show: true, color: AppConstants.primaryColor.withOpacity(0.08))
          )
        ]
      ))),
    ]));
  }

  Widget _buildQuickActionsHeader(LanguageProvider lp) {
    return SectionHeader(
      lp.translate('quick_actions'),
      trailing: TextButton.icon(
        icon: const Icon(Icons.tune, size: 18),
        label: const Text('Customize'),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShortcutManagerScreen())),
      ),
    );
  }

  Widget _buildShortcutGrid(LanguageProvider lp, ShortcutProvider sp) {
    if (sp.selectedShortcuts.isEmpty) return Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('No shortcuts selected. Use Customize to add some.', style: TextStyle(color: context.mutedText, fontSize: 13))));
    final columns = MediaQuery.of(context).size.width >= 700 ? 6 : 3;
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.zero, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.25), itemCount: sp.selectedShortcuts.length, itemBuilder: (context, index) { 
      final key = sp.selectedShortcuts[index]; 
      final data = Map<String, dynamic>.from(ShortcutProvider.allShortcuts[key]!); 
      String label = lp.translate(key);
      
      // Smart Detection for Milk Entry
      if (key == 'add_milk') {
        final hour = DateTime.now().hour;
        final isMorning = hour >= 19 || hour < 7;
        label = isMorning ? (lp.isTamil ? 'காலை பால் பதிவு' : 'Morning Milk') : (lp.isTamil ? 'மாலை பால் பதிவு' : 'Evening Milk');
      }
      
      return _buildQuickAction(label, data['icon'] as IconData, () => _navigate(key)); 
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

  Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 22),
          const SizedBox(height: 6),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500, fontSize: 12, height: 1.2)),
        ],
      ),
    );
  }
}
