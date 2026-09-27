import 'package:flutter/material.dart';
import '../constants.dart';
import 'dart:math' as math;

class PremiumLoading extends StatefulWidget {
  final String? message;
  const PremiumLoading({super.key, this.message});

  @override
  State<PremiumLoading> createState() => _PremiumLoadingState();
}

class _PremiumLoadingState extends State<PremiumLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Rotating outer ring
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppConstants.primaryColor.withOpacity(0.2),
                          width: 4,
                        ),
                      ),
                      child: CircularProgressIndicator(
                        value: 0.25,
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  );
                },
              ),
              // Pulsing inner icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Icon(Icons.water_drop, color: AppConstants.primaryColor, size: 30),
                  );
                },
                onEnd: () {
                  // This is just a pulsing effect, it will auto-reverse if we wrap it differently 
                  // but TweenAnimationBuilder doesn't repeat easily. 
                  // Let's use the controller instead.
                },
              ),
              // Use the controller for the pulsing too
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final pulse = 1.0 + 0.2 * math.sin(_controller.value * 2 * math.pi);
                  return Transform.scale(
                    scale: pulse,
                    child: Icon(Icons.water_drop, color: AppConstants.primaryColor, size: 30),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            widget.message ?? 'Loading DairyDay...',
            style: TextStyle(
              color: AppConstants.primaryColor.withOpacity(0.8),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// Full page wrapper
class LoadingPage extends StatelessWidget {
  final String? message;
  const LoadingPage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: PremiumLoading(message: message),
    );
  }
}
