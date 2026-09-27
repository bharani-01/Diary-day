import 'package:flutter/material.dart';
import '../constants.dart';

class PremiumLoading extends StatelessWidget {
  final String? message;
  const PremiumLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'Loading…',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
