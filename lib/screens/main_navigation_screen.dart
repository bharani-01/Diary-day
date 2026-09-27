import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../constants.dart';
import '../services/language_provider.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'dashboard_screen.dart';
import 'milk_history_screen.dart';
import 'cow_list_screen.dart';
import 'payments_expenses_screen.dart';
import 'calving_alerts_screen.dart';
import 'package:home_widget/home_widget.dart';
import 'milk_entry_screen.dart';
import 'add_expense_screen.dart';
import 'add_payment_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  StreamSubscription? _notificationsSubscription;
  final _db = DatabaseService();
  late final DateTime _appLaunchTime;
  
  @override
  void initState() {
    super.initState();
    _appLaunchTime = DateTime.now().toUtc().subtract(const Duration(seconds: 10));
    // Defer the initial widget launch check until after the first frame
    // so that Navigator context is fully available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForWidgetLaunch();
    });
    HomeWidget.widgetClicked.listen(_handleDeepLink);
    _listenToLiveNotifications();
    _setupPushNotifications();
  }

  Future<void> _setupPushNotifications() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      String? token = await messaging.getToken();
      if (token != null) {
        print('🚀 FCM Device Token registered: $token');
        await _db.registerPushToken(token, Platform.isAndroid ? 'android' : 'ios');
      }
      
      messaging.onTokenRefresh.listen((newToken) async {
        await _db.registerPushToken(newToken, Platform.isAndroid ? 'android' : 'ios');
      });
    } catch (e) {
      print('Error setting up Firebase Messaging: $e');
    }
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  void _listenToLiveNotifications() {
    print('📡 Subscribing to Supabase real-time notifications stream...');
    _notificationsSubscription = _db.getLiveNotificationsStream().listen((notifications) async {
      print('🔔 Notification stream update: Received ${notifications.length} rows');
      if (notifications.isNotEmpty) {
        final latest = notifications.first;
        print('👉 Latest Notification row: ID=${latest['id']}, Title="${latest['title']}", is_read=${latest['is_read']}');
        
        // Prevent showing old/historical notifications on initial stream load
        final createdAtStr = latest['created_at'];
        if (createdAtStr != null) {
          final createdAt = DateTime.tryParse(createdAtStr);
          if (createdAt != null) {
            final createdAtUtc = createdAt.toUtc();
            print('  - Created At (UTC): $createdAtUtc | App Launch Time (UTC): $_appLaunchTime');
            
            if (createdAtUtc.isBefore(_appLaunchTime)) {
              print('  - ⚠️ Skipping notification: Created before app launch (old/historical notification).');
              return;
            }
          }
        }
        
        final bool isRead = latest['is_read'] ?? false;
        if (!isRead) {
          final id = latest['id'] as String;
          print('  - 🚀 Triggering native system notification: "${latest['title']}"');
          
          await NotificationService.showImmediateNotification(
            id: id.hashCode,
            title: latest['title'] ?? '🔔 Farm Alert',
            body: latest['body'] ?? '',
          );
          
          print('  - ✅ Notification triggered. Marking as read in Supabase...');
          await _db.markNotificationAsRead(id);
        } else {
          print('  - ℹ️ Notification already marked as read. Skipping.');
        }
      }
    }, onError: (err) {
      print('❌ Error in real-time notifications stream: $err');
    });
  }

  void _checkForWidgetLaunch() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleDeepLink);
  }

  void _handleDeepLink(Uri? uri) {
    if (uri == null) return;
    if (!mounted) return;
    
    Widget? targetScreen;
    if (uri.host == 'widget') {
      final path = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      switch (path) {
        case 'add_milk':
          targetScreen = const MilkEntryScreen();
          break;
        case 'add_expense':
          targetScreen = const AddExpenseScreen();
          break;
        case 'add_payment':
          targetScreen = const AddPaymentScreen();
          break;
      }
    }
    
    if (targetScreen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen!));
    }
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);

    final List<Widget> _screens = [
      DashboardScreen(onMenuPressed: _onTabSelected),
      MilkHistoryScreen(onMenuPressed: _onTabSelected),
      CowListScreen(onMenuPressed: _onTabSelected),
      PaymentsExpensesScreen(onMenuPressed: _onTabSelected),
      CalvingAlertsScreen(onMenuPressed: _onTabSelected),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: AppConstants.primaryColor,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: lp.translate('dashboard'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.water_drop_outlined),
              activeIcon: const Icon(Icons.water_drop),
              label: lp.isTamil ? 'பால்' : 'Milk',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.pets_outlined),
              activeIcon: const Icon(Icons.pets),
              label: lp.isTamil ? 'பசுக்கள்' : 'Cows',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.payments_outlined),
              activeIcon: const Icon(Icons.payments),
              label: lp.isTamil ? 'நிதி' : 'Finance',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.notifications_none),
              activeIcon: const Icon(Icons.notifications),
              label: lp.translate('alerts'),
            ),
          ],
        ),
      ),
    );
  }
}
