import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rxdart/rxdart.dart';
import '../models/cow.dart';
import '../models/shift_milk_entry.dart';
import '../models/payment.dart';
import '../models/expense.dart';
import '../models/breeding_record.dart';
import '../models/health_record.dart';
import '../models/todo.dart';
import '../models/cow_milk_estimate.dart';
import '../models/vet_contact.dart';
import '../models/custom_alert.dart';
import '../models/monthly_budget.dart';
import '../models/milk_goal.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;

  Stream<List<BreedingRecord>> getBreedingRecordsStream() {
    return _supabase
        .from('breeding_records')
        .stream(primaryKey: ['id'])
        .order('breeding_date', ascending: false)
        .map((data) => data.map((json) => BreedingRecord.fromJson(json)).toList());
  }

  // --- Real-time Aggregated Dashboard ---
  Stream<Map<String, dynamic>> getDashboardDataStream() {
    return CombineLatestStream.combine6(
      getCowsStream(),
      getShiftMilkEntriesStream(),
      getPaymentsStream(),
      getExpensesStream(),
      getBreedingRecordsStream(),
      _supabase.from('health_records').stream(primaryKey: ['id']),
      (List<Cow> cows, List<ShiftMilkEntry> milk, List<Payment> payments, List<Expense> expenses, List<BreedingRecord> breeding, List<dynamic> health) {
        final activeCows = cows.where((c) => c.status == 'Active').toList();
        final now = DateTime.now();
        final todayStr = DateFormat('yyyy-MM-dd').format(now);
        final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

        double milkToday = milk
            .where((e) => DateFormat('yyyy-MM-dd').format(e.entryDate) == todayStr)
            .fold(0.0, (sum, e) => sum + e.quantity);
        
        double milkYesterday = milk
            .where((e) => DateFormat('yyyy-MM-dd').format(e.entryDate) == yesterdayStr)
            .fold(0.0, (sum, e) => sum + e.quantity);

        double totalIn = payments.fold(0.0, (sum, p) => sum + p.amount);
        double totalOut = expenses.fold(0.0, (sum, e) => sum + e.amount);

        // Calculate Alerts
        List<Map<String, dynamic>> alerts = [];
        for (var cow in cows) {
          final cowBreeding = breeding.where((b) => b.cowId == cow.id).toList();
          if (cowBreeding.isNotEmpty) {
            final calvingDate = cowBreeding.first.breedingDate.add(const Duration(days: 283));
            if (calvingDate.isAfter(now)) {
              alerts.add({'tag': cow.tagNumber, 'date': calvingDate});
            }
          }
        }
        alerts.sort((a, b) => a['date'].compareTo(b['date']));

        return {
          'totalCows': activeCows.length,
          'todayMilk': milkToday,
          'yesterdayMilk': milkYesterday,
          'netProfit': totalIn - totalOut,
          'weeklySpots': _calculateWeeklySpots(milk, now),
          'chartDates': _calculateChartDates(now),
          'fatTrend': _calculateQualityTrend(milk, now, 'fat'),
          'snfTrend': _calculateQualityTrend(milk, now, 'snf'),
          'monthlyMilkGrowth': _calculateMonthlyGrowth(milk, now),
          'yearlyIn': _calculateYearlyIn(payments, now),
          'yearlyOut': _calculateYearlyOut(expenses, now),
          'expenseCategories': _calculateExpenseCategories(expenses),
          'monthLabels': _calculateMonthLabels(now),
          'breedStats': _calculateBreedStats(cows),
          'healthStats': _calculateHealthStats(cows, health, now),
          'topAlerts': alerts.take(3).toList(),
        };
      },
    );
  }

  List<FlSpot> _calculateWeeklySpots(List<ShiftMilkEntry> milk, DateTime now) {
    Map<String, double> dailyTotals = {};
    List<String> dates = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      dailyTotals[dateKey] = 0;
      dates.add(dateKey);
    }
    for (var entry in milk) {
      final key = DateFormat('yyyy-MM-dd').format(entry.entryDate);
      if (dailyTotals.containsKey(key)) {
        dailyTotals[key] = (dailyTotals[key] ?? 0) + entry.quantity;
      }
    }
    List<FlSpot> spots = [];
    for (int i = 0; i < dates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyTotals[dates[i]]!));
    }
    return spots;
  }

  List<String> _calculateChartDates(DateTime now) {
    List<String> dates = [];
    for (int i = 6; i >= 0; i--) {
      dates.add(DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i))));
    }
    return dates;
  }

  List<double> _calculateYearlyIn(List<Payment> payments, DateTime now) {
    List<double> yearly = List.filled(12, 0.0);
    for (int i = 0; i < 12; i++) {
      final monthDate = DateTime(now.year, now.month - (11 - i), 1);
      yearly[i] = payments
          .where((p) => p.paymentDate.year == monthDate.year && p.paymentDate.month == monthDate.month)
          .fold(0.0, (sum, p) => sum + p.amount);
    }
    return yearly;
  }

  List<double> _calculateYearlyOut(List<Expense> expenses, DateTime now) {
    List<double> yearly = List.filled(12, 0.0);
    for (int i = 0; i < 12; i++) {
      final monthDate = DateTime(now.year, now.month - (11 - i), 1);
      yearly[i] = expenses
          .where((e) => e.expenseDate.year == monthDate.year && e.expenseDate.month == monthDate.month)
          .fold(0.0, (sum, e) => sum + e.amount);
    }
    return yearly;
  }

  List<String> _calculateMonthLabels(DateTime now) {
    List<String> labels = [];
    for (int i = 11; i >= 0; i--) {
      labels.add(DateFormat('MMM').format(DateTime(now.year, now.month - i, 1)));
    }
    return labels;
  }

  List<double> _calculateQualityTrend(List<ShiftMilkEntry> milk, DateTime now, String type) {
    List<double> trend = List.filled(7, 0.0);
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayEntries = milk.where((e) => DateFormat('yyyy-MM-dd').format(e.entryDate) == dateStr).toList();
      if (dayEntries.isNotEmpty) {
        double sum = dayEntries.fold(0.0, (s, e) => s + (type == 'fat' ? (e.fatPercentage ?? 0.0) : (e.snf ?? 0.0)));
        trend[6 - i] = sum / dayEntries.length;
      }
    }
    return trend;
  }

  List<double> _calculateMonthlyGrowth(List<ShiftMilkEntry> milk, DateTime now) {
    List<double> growth = List.filled(6, 0.0);
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      growth[5 - i] = milk
          .where((e) => e.entryDate.year == monthDate.year && e.entryDate.month == monthDate.month)
          .fold(0.0, (sum, e) => sum + e.quantity);
    }
    return growth;
  }

  Map<String, double> _calculateExpenseCategories(List<Expense> expenses) {
    Map<String, double> categories = {};
    for (var e in expenses) {
      categories[e.category] = (categories[e.category] ?? 0) + e.amount;
    }
    return categories;
  }

  Map<String, int> _calculateBreedStats(List<Cow> cows) {
    Map<String, int> stats = {};
    for (var cow in cows) {
      final breed = cow.breed ?? 'Other';
      stats[breed] = (stats[breed] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> _calculateHealthStats(List<Cow> cows, List<dynamic> health, DateTime now) {
    final recentThreshold = now.subtract(const Duration(days: 14));
    Set<String> treatedCowIds = {};
    for (var record in health) {
      final date = DateTime.parse(record['date']);
      if (date.isAfter(recentThreshold)) {
        treatedCowIds.add(record['cow_id']);
      }
    }
    int treated = treatedCowIds.length;
    return {
      'Healthy': cows.length - treated,
      'Recovering': treated,
    };
  }

  // --- Cows ---
  Stream<List<Cow>> getCowsStream() {
    return _supabase
        .from('cows')
        .stream(primaryKey: ['id'])
        .order('tag_number', ascending: true)
        .map((data) => data.map((json) => Cow.fromJson(json)).toList());
  }

  // Filtered stream for active milking cows
  Stream<List<Cow>> getActiveMilkingCowsStream() {
    return getCowsStream().map((list) => list.where((c) => c.status == 'Active' && !c.isDry).toList());
  }

  Future<void> markAsDry(String cowId, bool isDry) async {
    await _supabase.from('cows').update({'is_dry': isDry}).eq('id', cowId);
  }

  Future<void> sellCow(String cowId, String buyer, double price, DateTime date) async {
    // 1. Update cow status
    await _supabase.from('cows').update({
      'status': 'Sold',
      'buyer_name': buyer,
      'sale_price': price,
      'sale_date': date.toIso8601String().split('T')[0],
    }).eq('id', cowId);

    // 2. Add to payments (Income)
    final cow = (await _supabase.from('cows').select('tag_number').eq('id', cowId).single())['tag_number'];
    await _supabase.from('payments').insert({
      'amount': price,
      'buyer_name': buyer,
      'payment_date': date.toIso8601String().split('T')[0],
      'notes': 'Sale of Cow #$cow',
    });
  }

  Future<String> getNextTagNumber() async {
    final List response = await _supabase.from('cows').select('tag_number');
    if (response.isEmpty) return '101';
    
    // Try to find the max numerical tag
    int maxTag = 100;
    for (var item in response) {
      final tag = item['tag_number'].toString();
      final numMatch = RegExp(r'\d+').firstMatch(tag);
      if (numMatch != null) {
        final val = int.tryParse(numMatch.group(0)!);
        if (val != null && val > maxTag) maxTag = val;
      }
    }
    return (maxTag + 1).toString();
  }

  Future<void> purchaseCow(Cow cow, double price, String source) async {
    // 1. Add cow
    await _supabase.from('cows').insert({
      'tag_number': cow.tagNumber,
      'name': cow.name,
      'breed': cow.breed,
      'age': cow.age,
      'health_status': cow.healthStatus,
      'cow_type': cow.cowType,
      'source': source,
      'purchase_price': price,
      'health_at_purchase': cow.healthStatus,
    });

    // 2. Add to expenses
    await _supabase.from('expenses').insert({
      'amount': price,
      'category': 'Cattle Purchase',
      'expense_date': DateTime.now().toIso8601String().split('T')[0],
      'notes': 'Purchase of Cow #${cow.tagNumber} from $source',
    });
  }

  // --- Todo List ---
  Stream<List<Todo>> getTodosStream() {
    return _supabase
        .from('todo_list')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Todo.fromJson(json)).toList());
  }

  Future<String> addTodo(Todo todo) async {
    final response = await _supabase.from('todo_list').insert(todo.toJson()).select('id').single();
    return response['id'];
  }

  Future<void> toggleTodo(String id, bool isDone) async {
    await _supabase.from('todo_list').update({'is_done': isDone}).eq('id', id);
  }

  Future<void> deleteTodo(String id) async {
    await _supabase.from('todo_list').delete().eq('id', id);
  }

  Future<List<Cow>> getCows() async {
    final List response = await _supabase.from('cows').select().order('tag_number', ascending: true);
    return response.map((json) => Cow.fromJson(json)).toList();
  }

  Future<void> addCow(Cow cow) async {
    await _supabase.from('cows').insert(cow.toJson());
  }

  Future<void> updateCow(Cow cow) async {
    await _supabase.from('cows').update(cow.toJson()).eq('id', cow.id);
  }

  Future<void> deleteCow(String id) async {
    await _supabase.from('cows').delete().eq('id', id);
  }

  Future<Cow?> getCow(String id) async {
    final List response = await _supabase.from('cows').select().eq('id', id);
    if (response.isEmpty) return null;
    return Cow.fromJson(response.first);
  }

  Future<String> getNextCowTag() async {
    try {
      final List response = await _supabase.from('cows').select('tag_number');
      if (response.isEmpty) return 'KRB-101';
      
      int maxNum = 100;
      for (var row in response) {
        final tag = row['tag_number'] as String;
        if (tag.startsWith('KRB-')) {
          final numStr = tag.substring(4);
          final num = int.tryParse(numStr);
          if (num != null && num > maxNum) {
            maxNum = num;
          }
        }
      }
      return 'KRB-${maxNum + 1}';
    } catch (e) {
      return 'KRB-101';
    }
  }

  Future<String?> uploadCowImage(File imageFile, String tagNumber) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeTag = tagNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = 'cow_${safeTag}_$timestamp.jpg';
      
      final bytes = await imageFile.readAsBytes();
      await _supabase.storage.from('cow-images').uploadBinary(
        fileName, 
        bytes,
        fileOptions: const FileOptions(
          cacheControl: '31536000',
          upsert: false,
          contentType: 'image/jpeg',
        ),
      );

      final String publicUrl = _supabase.storage.from('cow-images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  Future<List<String>> uploadMultipleCowImages(List<File> imageFiles, String tagNumber) async {
    List<String> urls = [];
    for (var file in imageFiles) {
      final url = await uploadCowImage(file, tagNumber);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  // --- Shift Milk Entries ---
  Stream<List<ShiftMilkEntry>> getShiftMilkEntriesStream() {
    return _supabase
        .from('shift_milk_entries')
        .stream(primaryKey: ['id'])
        .order('entry_date', ascending: false)
        .map((data) => data.map((json) => ShiftMilkEntry.fromJson(json)).toList());
  }

  Future<List<ShiftMilkEntry>> getShiftMilkEntries() async {
    final List response = await _supabase
        .from('shift_milk_entries')
        .select()
        .order('entry_date', ascending: false);
    return response.map((json) => ShiftMilkEntry.fromJson(json)).toList();
  }

  Future<void> addShiftMilkEntry(ShiftMilkEntry entry) async {
    await _supabase.from('shift_milk_entries').upsert(
      entry.toJson(),
      onConflict: 'entry_date,shift',
    );
  }

  Future<ShiftMilkEntry?> getShiftMilkEntry(String date, String shift) async {
    final List response = await _supabase
        .from('shift_milk_entries')
        .select()
        .eq('entry_date', date)
        .eq('shift', shift);
    
    if (response.isEmpty) return null;
    return ShiftMilkEntry.fromJson(response.first);
  }

  // --- Payments ---
  Stream<List<Payment>> getPaymentsStream() {
    return _supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .order('payment_date', ascending: false)
        .map((data) => data.map((json) => Payment.fromJson(json)).toList());
  }

  Future<List<Payment>> getPayments() async {
    final List response = await _supabase.from('payments').select().order('payment_date', ascending: false);
    return response.map((json) => Payment.fromJson(json)).toList();
  }

  Future<void> addPayment(Payment payment) async {
    await _supabase.from('payments').insert(payment.toJson());
  }

  // --- Expenses ---
  Stream<List<Expense>> getExpensesStream() {
    return _supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .order('expense_date', ascending: false)
        .map((data) => data.map((json) => Expense.fromJson(json)).toList());
  }

  Future<List<Expense>> getExpenses() async {
    final List response = await _supabase.from('expenses').select().order('expense_date', ascending: false);
    return response.map((json) => Expense.fromJson(json)).toList();
  }

  Future<void> addExpense(Expense expense) async {
    await _supabase.from('expenses').insert(expense.toJson());
  }

  // --- Financials Stream ---
  Stream<Map<String, List>> getFinancialsStream() {
    return CombineLatestStream.combine2(
      getPaymentsStream(),
      getExpensesStream(),
      (List<Payment> p, List<Expense> e) => {'payments': p, 'expenses': e},
    );
  }

  // --- Breeding Records ---
  Future<void> addBreedingRecord(BreedingRecord record) async {
    await _supabase.from('breeding_records').insert(record.toJson());
  }

  Future<List<BreedingRecord>> getBreedingRecordsForCow(String cowId) async {
    final List response = await _supabase
        .from('breeding_records')
        .select()
        .eq('cow_id', cowId)
        .order('breeding_date', ascending: false);
    return response.map((json) => BreedingRecord.fromJson(json)).toList();
  }

  // --- Health Records ---
  Future<void> addHealthRecord(HealthRecord record) async {
    await _supabase.from('health_records').insert(record.toJson());
  }

  Future<List<HealthRecord>> getHealthRecordsForCow(String cowId) async {
    final List response = await _supabase
        .from('health_records')
        .select()
        .eq('cow_id', cowId)
        .order('date', ascending: false);
    return response.map((json) => HealthRecord.fromJson(json)).toList();
  }

  // --- Dashboard Stats (Enhanced) ---
  Future<Map<String, dynamic>> getDashboardStats() async {
    final List cowsData = await _supabase.from('cows').select('id');
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final yesterdayStr = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
    final List milkToday = await _supabase.from('shift_milk_entries').select('quantity').eq('entry_date', todayStr);
    final List milkYesterday = await _supabase.from('shift_milk_entries').select('quantity').eq('entry_date', yesterdayStr);
    double totalMilkToday = milkToday.fold(0, (sum, item) => sum + (item['quantity'] as num).toDouble());
    double totalMilkYesterday = milkYesterday.fold(0, (sum, item) => sum + (item['quantity'] as num).toDouble());
    final List payments = await _supabase.from('payments').select('amount');
    final List expenses = await _supabase.from('expenses').select('amount');
    double totalIn = payments.fold(0, (sum, item) => sum + (item['amount'] as num).toDouble());
    double totalOut = expenses.fold(0, (sum, item) => sum + (item['amount'] as num).toDouble());
    return {
      'totalCows': cowsData.length,
      'todayMilk': totalMilkToday,
      'yesterdayMilk': totalMilkYesterday,
      'netProfit': totalIn - totalOut,
    };
  }

  // --- Cow Milk Estimates ---
  Future<void> saveCowMilkEstimates(DateTime date, String shift, Map<String, double> cowEstimates) async {
    final dateStr = date.toIso8601String().split('T')[0];
    // Delete existing estimates for this date+shift
    await _supabase.from('cow_milk_estimates')
        .delete()
        .eq('shift_entry_date', dateStr)
        .eq('shift', shift);
    // Insert new estimates
    for (final entry in cowEstimates.entries) {
      if (entry.value > 0) {
        await _supabase.from('cow_milk_estimates').insert({
          'shift_entry_date': dateStr,
          'shift': shift,
          'cow_id': entry.key,
          'estimated_liters': entry.value,
        });
      }
    }
  }

  Future<List<CowMilkEstimate>> getCowMilkEstimatesForCow(String cowId) async {
    final List response = await _supabase
        .from('cow_milk_estimates')
        .select()
        .eq('cow_id', cowId)
        .order('shift_entry_date', ascending: false);
    return response.map((json) => CowMilkEstimate.fromJson(json)).toList();
  }

  Future<Map<String, double>> getCowMilkEstimatesForShift(String date, String shift) async {
    final List response = await _supabase
        .from('cow_milk_estimates')
        .select()
        .eq('shift_entry_date', date)
        .eq('shift', shift);
    Map<String, double> estimates = {};
    for (var row in response) {
      estimates[row['cow_id']] = (row['estimated_liters'] as num).toDouble();
    }
    return estimates;
  }

  // --- Vet Contacts ---
  Stream<List<VetContact>> getVetContactsStream() {
    return _supabase
        .from('vet_contacts')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .map((data) => data.map((json) => VetContact.fromJson(json)).toList());
  }

  Future<void> addVetContact(VetContact contact) async {
    await _supabase.from('vet_contacts').insert(contact.toJson());
  }

  Future<void> updateVetContact(String id, VetContact contact) async {
    await _supabase.from('vet_contacts').update(contact.toJson()).eq('id', id);
  }

  Future<void> deleteVetContact(String id) async {
    await _supabase.from('vet_contacts').delete().eq('id', id);
  }

  // --- Custom Alerts ---
  Stream<List<CustomAlert>> getCustomAlertsStream() {
    return _supabase
        .from('custom_alerts')
        .stream(primaryKey: ['id'])
        .order('alert_date', ascending: true)
        .map((data) => data.map((json) => CustomAlert.fromJson(json)).toList());
  }

  Future<void> addCustomAlert(CustomAlert alert) async {
    await _supabase.from('custom_alerts').insert(alert.toJson());
  }

  Future<void> dismissCustomAlert(String id) async {
    await _supabase.from('custom_alerts').update({'is_dismissed': true}).eq('id', id);
  }

  Future<void> deleteCustomAlert(String id) async {
    await _supabase.from('custom_alerts').delete().eq('id', id);
  }

  // --- Real-time Notifications ---
  Stream<List<Map<String, dynamic>>> getLiveNotificationsStream() {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> markNotificationAsRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> registerPushToken(String token, String platform) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _supabase.from('user_push_tokens').upsert({
        'user_id': userId,
        'push_token': token,
        'device_platform': platform,
      });
    } catch (e) {
      print('Error registering push token: $e');
    }
  }

  // --- Monthly Budgets ---
  Future<List<MonthlyBudget>> getBudgetsForMonth(int month, int year) async {
    final List response = await _supabase
        .from('monthly_budgets')
        .select()
        .eq('month', month)
        .eq('year', year);
    return response.map((json) => MonthlyBudget.fromJson(json)).toList();
  }

  Future<void> upsertBudget(MonthlyBudget budget) async {
    await _supabase.from('monthly_budgets').upsert(
      budget.toJson(),
      onConflict: 'category,month,year',
    );
  }

  Future<void> deleteBudget(String id) async {
    await _supabase.from('monthly_budgets').delete().eq('id', id);
  }

  // --- Milk Goals ---
  Future<MilkGoal?> getMilkGoal(int month, int year) async {
    final List response = await _supabase
        .from('milk_goals')
        .select()
        .eq('month', month)
        .eq('year', year);
    if (response.isEmpty) return null;
    return MilkGoal.fromJson(response.first);
  }

  Future<void> upsertMilkGoal(MilkGoal goal) async {
    await _supabase.from('milk_goals').upsert(
      goal.toJson(),
      onConflict: 'month,year',
    );
  }

  // --- Recurring Expense Auto-Creation ---
  Future<void> autoCreateRecurringExpenses() async {
    final List response = await _supabase
        .from('expenses')
        .select()
        .eq('is_recurring', true);
    
    final now = DateTime.now();
    final todayStr = now.toIso8601String().split('T')[0];
    
    for (var row in response) {
      final expense = Expense.fromJson(row);
      final lastDate = expense.lastAutoDate ?? expense.expenseDate;
      DateTime? nextDate;
      
      switch (expense.frequency) {
        case 'daily':
          nextDate = lastDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextDate = lastDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          nextDate = DateTime(lastDate.year, lastDate.month + 1, lastDate.day);
          break;
      }
      
      if (nextDate != null && !nextDate.isAfter(now)) {
        // Create the auto-entry
        await _supabase.from('expenses').insert({
          'title': expense.title,
          'category': expense.category,
          'amount': expense.amount,
          'expense_date': todayStr,
          'notes': '(Auto) ${expense.notes ?? ''}',
          'cow_id': expense.cowId,
          'cow_tag': expense.cowTag,
        });
        // Update the last auto date on the recurring template
        await _supabase.from('expenses')
            .update({'last_auto_date': todayStr})
            .eq('id', expense.id);
      }
    }
  }

  // --- Cow Timeline (aggregated events for one cow) ---
  Future<List<Map<String, dynamic>>> getCowTimeline(String cowId) async {
    List<Map<String, dynamic>> timeline = [];
    
    // Health records
    final healthRes = await _supabase.from('health_records').select().eq('cow_id', cowId);
    for (var r in healthRes) {
      timeline.add({
        'type': 'health',
        'date': DateTime.parse(r['date']),
        'title': r['treatment'] ?? 'Health Event',
        'subtitle': r['type'] ?? '',
        'icon': 'health',
      });
    }
    
    // Breeding records
    final breedingRes = await _supabase.from('breeding_records').select().eq('cow_id', cowId);
    for (var r in breedingRes) {
      timeline.add({
        'type': 'breeding',
        'date': DateTime.parse(r['breeding_date']),
        'title': 'Breeding Event',
        'subtitle': r['details'] ?? '',
        'icon': 'breeding',
      });
    }
    
    // Milk estimates
    final milkRes = await _supabase.from('cow_milk_estimates').select().eq('cow_id', cowId).order('shift_entry_date', ascending: false).limit(30);
    for (var r in milkRes) {
      timeline.add({
        'type': 'milk',
        'date': DateTime.parse(r['shift_entry_date']),
        'title': '${r['shift']} Milk: ${r['estimated_liters']}L',
        'subtitle': r['shift'],
        'icon': 'milk',
      });
    }
    
    // Linked expenses
    final expRes = await _supabase.from('expenses').select().eq('cow_id', cowId);
    for (var r in expRes) {
      timeline.add({
        'type': 'expense',
        'date': DateTime.parse(r['expense_date']),
        'title': '₹${r['amount']} - ${r['title']}',
        'subtitle': r['category'] ?? '',
        'icon': 'expense',
      });
    }
    
    // Linked calves (born to this cow)
    final calvesRes = await _supabase.from('cows').select().eq('mother_cow_id', cowId);
    for (var r in calvesRes) {
      final dobStr = r['dob'] ?? r['created_at'];
      timeline.add({
        'type': 'calf',
        'date': DateTime.parse(dobStr),
        'title': 'Calf Born: ${r['tag_number']}${r['name'] != null ? ' (${r['name']})' : ''}',
        'subtitle': r['breed'] ?? '',
        'icon': 'calf',
      });
    }
    
    // Sort by date descending
    timeline.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return timeline;
  }

  // --- Expenses for a specific cow ---
  Future<List<Expense>> getExpensesForCow(String cowId) async {
    final List response = await _supabase.from('expenses').select().eq('cow_id', cowId).order('expense_date', ascending: false);
    return response.map((json) => Expense.fromJson(json)).toList();
  }
}

