import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../utils/error_handler.dart';

class GlobalErrorView extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final bool isFullScreen;

  const GlobalErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.isFullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    final appError = error is AppError ? error : ErrorHandler.handle(error);
    
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIcon(appError),
          const SizedBox(height: 24),
          Text(
            appError.title,
            style: TextStyle(
              fontSize: isFullScreen ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.errorColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            appError.message,
            style: TextStyle(
              fontSize: isFullScreen ? 16 : 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildSuggestionCard(context, appError),
          const SizedBox(height: 32),
          _buildActionButtons(context, appError),
        ],
      ),
    );

    if (isFullScreen) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: content),
      );
    }

    return Center(child: content);
  }

  Widget _buildIcon(AppError error) {
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: isFullScreen ? 64 : 48, color: color),
    );
  }

  Widget _buildSuggestionCard(BuildContext context, AppError error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 22, color: AppConstants.primaryColor),
              const SizedBox(width: 10),
              Text(
                'How to fix:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            error.suggestion,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppError error) {
    return Column(
      children: [
        if (onRetry != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text('Try Again', style: TextStyle(color: Theme.of(context).cardColor, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: error.rawError));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error details copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy Technical Details'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
