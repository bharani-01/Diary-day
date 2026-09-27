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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: 20),
            Text(
              error.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppConstants.errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error.message,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.secondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.primaryColor.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 20, color: AppConstants.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        'How to fix:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.suggestion,
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: error.rawError));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error details copied to clipboard')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Copy Error'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color color;

    switch (error.type) {
      case ErrorType.internet:
        iconData = Icons.wifi_off_rounded;
        color = Colors.blue;
        break;
      case ErrorType.database:
        iconData = Icons.storage_rounded;
        color = Colors.orange;
        break;
      case ErrorType.timeout:
        iconData = Icons.timer_off_rounded;
        color = Colors.amber;
        break;
      case ErrorType.unknown:
      default:
        iconData = Icons.error_outline_rounded;
        color = AppConstants.errorColor;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 48, color: color),
    );
  }
}
