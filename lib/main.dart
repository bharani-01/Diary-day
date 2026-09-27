import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'constants.dart';
import 'services/language_provider.dart';
import 'services/shortcut_provider.dart';
import 'services/notification_service.dart';
import 'services/theme_provider.dart';
import 'services/privacy_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/dashboard_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    await NotificationService.init();
    final notification = message.notification;
    if (notification != null) {
      await NotificationService.showImmediateNotification(
        id: message.messageId.hashCode,
        title: notification.title ?? '🔔 Farm Alert',
        body: notification.body ?? '',
      );
    }
  } catch (e) {
    debugPrint('Error in FCM background handler: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }
  }

  await NotificationService.init();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Auto-recover from PGRST301: Clear cached session if project backend changed
  final client = Supabase.instance.client;
  final session = client.auth.currentSession;
  if (session != null) {
    try {
      final jwt = session.accessToken;
      final parts = jwt.split('.');
      if (parts.length == 3) {
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        final data = jsonDecode(payload);
        
        // Extract cached reference robustly for both anon and user JWTs
        String? cachedRef = data['ref'];
        if (cachedRef == null && data['iss'] != null) {
          final iss = data['iss'].toString();
          if (iss.startsWith('http')) {
            final issUri = Uri.tryParse(iss);
            if (issUri != null && issUri.host.endsWith('.supabase.co')) {
              cachedRef = issUri.host.split('.')[0];
            }
          }
        }
        
        final currentUri = Uri.parse(AppConstants.supabaseUrl);
        final currentRef = currentUri.host.split('.')[0];
        
        if (cachedRef != null && cachedRef != currentRef) {
          debugPrint('Backend ref changed from $cachedRef to $currentRef. Clearing cached session locally...');
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('SUPABASE_PERSIST_SESSION_KEY');
          } catch (_) {}
          try {
            await client.auth.signOut();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  // Active Diagnostic Self-Healing for PGRST301
  try {
    await client.from('cows').select('id').limit(1).maybeSingle();
  } catch (e) {
    if (e is PostgrestException && e.code == 'PGRST301') {
      debugPrint('Stale JWT detected (PGRST301). Force clearing cached session locally...');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('SUPABASE_PERSIST_SESSION_KEY');
      } catch (_) {}
      try {
        await client.auth.signOut();
      } catch (_) {}
    }
  }

  await NotificationService.requestPermissions();
  await NotificationService.autoScheduleFromPrefs();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ShortcutProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PrivacyProvider()),
      ],
      child: const DairyDayApp(),
    ),
  );
}

class DairyDayApp extends StatelessWidget {
  const DairyDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'KRB Dairy Farms',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const SplashScreen(),
    );
  }

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      primary: AppConstants.primaryColor,
      onPrimary: Colors.white,
      surface: const Color(0xFFF7FAF8),
      onSurface: Colors.black87,
      brightness: Brightness.light,
    );

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF7FAF8),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE5E7EB),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE5E7EB), thickness: 1, space: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.cardRadius)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.white,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: AppConstants.primaryColor.withOpacity(0.2),
        labelStyle: const TextStyle(color: Colors.black87),
      ),
      textTheme: GoogleFonts.workSansTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.epilogue(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        headlineMedium: GoogleFonts.epilogue(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const darkSurface = Color(0xFF121212);
    const darkCard = Color(0xFF1E1E1E);
    const darkInputFill = Color(0xFF2C2C2C);
    const darkBorder = Color(0xFF3A3A3A);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      primary: AppConstants.primaryColor,
      onPrimary: Colors.white,
      surface: darkSurface,
      onSurface: Colors.white,
      brightness: Brightness.dark,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkSurface,
      cardColor: darkCard,
      dividerColor: darkBorder,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: darkBorder)),
      ),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1, space: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.cardRadius)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: darkCard,
        textColor: Colors.white,
        iconColor: Colors.white70,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkInputFill,
        selectedColor: AppConstants.primaryColor.withOpacity(0.3),
        labelStyle: const TextStyle(color: Colors.white),
      ),
      textTheme: GoogleFonts.workSansTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.epilogue(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.epilogue(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
