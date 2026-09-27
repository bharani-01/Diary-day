import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../constants.dart';

class MilkEntrySuccessScreen extends StatelessWidget {
  final double quantity;
  final String shift;

  const MilkEntrySuccessScreen({
    super.key,
    required this.quantity,
    required this.shift,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.containerPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.network(
                'https://assets10.lottiefiles.com/packages/lf20_qc8v1m.json',
                width: 150,
                height: 150,
                repeat: false,
              ),
              const SizedBox(height: 32),
              Text(
                'Success!',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Saved $quantity Liters for $shift shift.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 64),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Back to Dashboard', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
