import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../utils/error_handler.dart';
import 'error_dialog.dart';

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
    final AppError appError = error is AppError ? error : ErrorHandler.handle(error);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withOpacity(0.65);

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ErrorDialog.errorIcon(appError.type), size: 36, color: AppConstants.dangerColor),
            const SizedBox(height: 16),
            Text(
              appError.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              appError.message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: muted, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              appError.suggestion,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: muted, height: 1.4),
            ),
            const SizedBox(height: 24),
            if (onRetry != null)
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  minimumSize: const Size(160, 44),
                ),
              ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: appError.rawError));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error details copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy technical details'),
              style: TextButton.styleFrom(foregroundColor: muted),
            ),
          ],
        ),
      ),
    );

    if (isFullScreen) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: content),
      );
    }

    return Center(child: content);
  }
}
