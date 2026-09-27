import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_navigation_screen.dart';
import 'login_screen.dart';
import '../constants.dart';
import '../services/biometric_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );

    _controller.forward();

    _navigateToMain();
  }

  Future<void> _navigateToMain() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    
    if (mounted) {
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session == null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        final bool biometricEnabled = await BiometricService.isBiometricEnabled();
        
        if (biometricEnabled) {
          final bool authenticated = await BiometricService.authenticate();
          if (!authenticated) {
            setState(() => _showRetry = true);
            return;
          }
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Display the logo
                Image.asset(
                  'assets/logo.png',
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if logo.png is not yet placed in assets
                    return Column(
                      children: [
                        const Icon(Icons.water_drop, size: 80, color: AppConstants.primaryColor),
                        const SizedBox(height: 16),
                        const Text(
                          'KRB Dairy Farms',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'PURE • FRESH • QUALITY',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 4,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                ),
                if (_showRetry) ...[
                  const SizedBox(height: 32),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _showRetry = false);
                      _navigateToMain();
                    },
                    icon: const Icon(Icons.refresh, color: AppConstants.primaryColor),
                    label: const Text('Retry Authentication', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
