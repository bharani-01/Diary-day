import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../utils/error_handler.dart';

class ErrorDialog extends StatelessWidget {
  final AppError error;

  const ErrorDialog({super.key, required this.error});

  static void show(BuildContext context, dynamic rawError) {
    final appError = ErrorHandler.handle(rawError);
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(error: appError),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    return AlertDialog(
      icon: Icon(errorIcon(error.type), color: AppConstants.dangerColor, size: 28),
      title: Text(error.title, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error.message, style: TextStyle(fontSize: 14, color: muted, height: 1.4)),
          const SizedBox(height: 12),
          Text(
            error.suggestion,
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.4),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: error.rawError));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error details copied to clipboard')),
            );
          },
          child: const Text('Copy details'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(backgroundColor: AppConstants.primaryColor),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }

  static IconData errorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.internet:
        return Icons.wifi_off_rounded;
      case ErrorType.database:
        return Icons.storage_rounded;
      case ErrorType.timeout:
        return Icons.timer_off_outlined;
      case ErrorType.unknown:
      default:
        return Icons.error_outline_rounded;
    }
  }
}
