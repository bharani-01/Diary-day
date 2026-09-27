import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/app_ui.dart';

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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppConstants.successColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, size: 36, color: AppConstants.successColor),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Entry saved',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$quantity L recorded for the $shift shift.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: context.mutedText),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    style: primaryButtonStyle(),
                    child: const Text('Back to dashboard'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
