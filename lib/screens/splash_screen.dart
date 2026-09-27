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
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                width: 160,
                height: 160,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'KRB Dairy Farms',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.primaryColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                ),
              ),
              if (_showRetry) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _showRetry = false);
                    _navigateToMain();
                  },
                  icon: const Icon(Icons.fingerprint, size: 18),
                  label: const Text('Retry authentication'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppConstants.primaryColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
