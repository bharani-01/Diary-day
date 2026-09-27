import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final files = libDir.listSync(recursive: true)
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => File(f.path))
      .toList();

  int totalFixes = 0;
  int filesFixed = 0;

  for (final file in files) {
    String content = file.readAsStringSync();
    final original = content;
    
    // Skip model files and non-UI services
    final path = file.path.replaceAll('\\', '/');
    if (path.contains('/models/') || path.contains('/utils/')) continue;
    if (path.endsWith('theme_provider.dart') || path.endsWith('privacy_provider.dart')) continue;
    if (path.endsWith('database_service.dart') || path.endsWith('report_service.dart')) continue;
    if (path.endsWith('notification_service.dart') || path.endsWith('biometric_service.dart')) continue;
    if (path.endsWith('weather_service.dart') || path.endsWith('error_handler.dart')) continue;
    if (path.endsWith('language_provider.dart') || path.endsWith('shortcut_provider.dart')) continue;
    if (path.endsWith('confirm_image_screen.dart')) continue; // Intentionally dark screen
    if (path.endsWith('splash_screen.dart')) continue; // Already theme-aware
    if (path.endsWith('main.dart')) continue; // Already fixed
    if (path.endsWith('constants.dart')) continue; // Already fixed

    // ========== FOREGROUND COLOR ON APPBARS ==========
    // Remove hardcoded foregroundColor since appBarTheme handles it
    content = content.replaceAll('foregroundColor: Colors.black87,', '');
    content = content.replaceAll('foregroundColor: Colors.black87', '');
    
    // ========== APPBAR BACKGROUND COLOR ==========
    // Remove hardcoded backgroundColor on AppBars - let appBarTheme handle
    // These are in AppBar constructors. We replace with empty to let theme handle.
    content = content.replaceAll(
      'backgroundColor: Theme.of(context).colorScheme.surface,',
      '',
    );
    // Leave specific gradient/custom AppBar backgrounds alone

    // ========== SCAFFOLD BACKGROUND ==========
    content = content.replaceAll(
      'backgroundColor: Theme.of(context).colorScheme.surface,',
      'backgroundColor: Theme.of(context).scaffoldBackgroundColor,',
    );
    
    // ========== CONTAINER/CARD WHITE BACKGROUNDS ==========
    // BoxDecoration color: Colors.white → Theme.of(context).cardColor
    content = content.replaceAll(
      'color: Colors.white,',
      'color: Theme.of(context).cardColor,',
    );

    // ========== GREY.SHADE50 BACKGROUNDS ==========
    content = content.replaceAll(
      'color: Colors.grey.shade50,',
      'color: Theme.of(context).cardColor,',
    );
    content = content.replaceAll(
      'color: Colors.grey.shade50',
      'color: Theme.of(context).cardColor',
    );
    content = content.replaceAll(
      "Colors.grey[50]",
      "Theme.of(context).cardColor",
    );
    content = content.replaceAll(
      'color: Colors.grey.shade50.withOpacity(0.8),',
      'color: Theme.of(context).cardColor,',
    );

    // ========== GREY.SHADE100 BACKGROUNDS ==========
    content = content.replaceAll(
      'backgroundColor: Colors.grey.shade100',
      'backgroundColor: Theme.of(context).dividerColor',
    );
    content = content.replaceAll(
      'color: Colors.grey.shade100,',
      'color: Theme.of(context).cardColor,',
    );

    // ========== FILL COLORS ==========
    content = content.replaceAll(
      'fillColor: Colors.white,',
      'fillColor: Theme.of(context).inputDecorationTheme.fillColor,',
    );
    content = content.replaceAll(
      'fillColor: Colors.white',
      'fillColor: Theme.of(context).inputDecorationTheme.fillColor',
    );
    content = content.replaceAll(
      'fillColor: Colors.grey.shade50,',
      'fillColor: Theme.of(context).inputDecorationTheme.fillColor,',
    );
    content = content.replaceAll(
      'fillColor: Colors.grey.shade50',
      'fillColor: Theme.of(context).inputDecorationTheme.fillColor',
    );
    content = content.replaceAll(
      'fillColor: Colors.grey.shade100,',
      'fillColor: Theme.of(context).inputDecorationTheme.fillColor,',
    );

    // ========== TILE COLOR ==========
    content = content.replaceAll(
      'tileColor: Colors.white,',
      'tileColor: Theme.of(context).cardColor,',
    );
    content = content.replaceAll(
      'tileColor: Colors.grey.shade50,',
      'tileColor: Theme.of(context).cardColor,',
    );
    content = content.replaceAll(
      'tileColor: Colors.grey.shade50',
      'tileColor: Theme.of(context).cardColor',
    );

    // ========== BORDERS ==========
    content = content.replaceAll(
      'Border.all(color: Colors.grey.shade100)',
      'Border.all(color: Theme.of(context).dividerColor)',
    );
    content = content.replaceAll(
      'Border.all(color: Colors.grey.shade200)',
      'Border.all(color: Theme.of(context).dividerColor)',
    );
    content = content.replaceAll(
      'Border.all(color: Colors.grey.shade300)',
      'Border.all(color: Theme.of(context).dividerColor)',
    );
    content = content.replaceAll(
      'BorderSide(color: Colors.grey.shade100)',
      'BorderSide(color: Theme.of(context).dividerColor)',
    );
    content = content.replaceAll(
      'BorderSide(color: Colors.grey.shade200)',
      'BorderSide(color: Theme.of(context).dividerColor)',
    );
    content = content.replaceAll(
      'BorderSide(color: Colors.grey.shade300)',
      'BorderSide(color: Theme.of(context).dividerColor)',
    );
    content = content.replaceAll(
      'BorderSide(color: Colors.grey.shade400)',
      'BorderSide(color: Theme.of(context).dividerColor)',
    );

    // ========== TEXT COLORS ==========
    // Colors.black87 → Theme.of(context).colorScheme.onSurface (already done by prior script in some places)
    // Target remaining text-specific patterns
    content = content.replaceAll(
      'color: Colors.black87)',
      'color: Theme.of(context).colorScheme.onSurface)',
    );
    content = content.replaceAll(
      'color: Colors.black54)',
      'color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))',
    );
    content = content.replaceAll(
      'color: Colors.black)',
      'color: Theme.of(context).colorScheme.onSurface)',
    );

    // Specific patterns for sell/drying/purchase screens
    content = content.replaceAll(
      'TextStyle(color: Colors.black, fontWeight: FontWeight.bold)',
      'TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)',
    );
    content = content.replaceAll(
      'BackButton(color: Colors.black)',
      'BackButton(color: Theme.of(context).colorScheme.onSurface)',
    );

    // ========== GREY TEXT (subtitle/helper colors) ==========
    content = content.replaceAll(
      'color: Colors.grey.shade500,',
      'color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),',
    );
    content = content.replaceAll(
      'color: Colors.grey.shade600,',
      'color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),',
    );
    content = content.replaceAll(
      'color: Colors.grey.shade700,',
      'color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),',
    );
    content = content.replaceAll(
      'color: Colors.grey.shade600)',
      'color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))',
    );
    content = content.replaceAll(
      'color: Colors.grey.shade700)',
      'color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))',
    );

    // ========== CHIP / CHOICE CHIP BACKGROUNDS ==========
    content = content.replaceAll(
      'backgroundColor: Colors.grey.shade100,',
      'backgroundColor: Theme.of(context).chipTheme.backgroundColor,',
    );

    // ========== BOTTOM SHEET BACKGROUNDS ==========
    content = content.replaceAll(
      'const BoxDecoration(color: Theme.of(context).cardColor,',
      'BoxDecoration(color: Theme.of(context).cardColor,',
    );

    // ========== DIALOG BACKGROUNDS ==========
    // Already handled by dialogTheme

    // ========== FIX CONST ISSUES ==========
    // After our replacements, any `const` before a widget that now has Theme.of(context) is invalid
    // Fix common patterns:
    content = content.replaceAll('const Icon(Icons.menu, color: Theme.of', 'Icon(Icons.menu, color: Theme.of');
    content = content.replaceAll('const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Theme.of', 'TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Theme.of');
    content = content.replaceAll('const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of', 'TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of');
    content = content.replaceAll('const TextStyle(fontSize: 14, color: Theme.of', 'TextStyle(fontSize: 14, color: Theme.of');
    content = content.replaceAll('const TextStyle(fontSize: 18, color: Theme.of', 'TextStyle(fontSize: 18, color: Theme.of');
    content = content.replaceAll('const BackButton(color: Theme.of', 'BackButton(color: Theme.of');
    content = content.replaceAll('const CircleAvatar(', 'CircleAvatar(');
    
    // Generic const fix for BoxDecoration with Theme.of
    content = content.replaceAll('const BoxDecoration(color: Theme.of', 'BoxDecoration(color: Theme.of');
    
    // Generic const fix for Border.all with Theme.of
    // These get embedded inside const decorations that break
    
    // Fix any remaining "const" before a TextStyle/Icon that references Theme.of(context)
    // This regex-like approach handles most patterns
    final constPatterns = [
      RegExp(r'const\s+TextStyle\(([^)]*?)Theme\.of\(context\)'),
      RegExp(r'const\s+Icon\(([^)]*?)Theme\.of\(context\)'),
      RegExp(r'const\s+BoxDecoration\(([^)]*?)Theme\.of\(context\)'),
      RegExp(r'const\s+InputDecoration\(([^)]*?)Theme\.of\(context\)'),
      RegExp(r'const\s+BackButton\(([^)]*?)Theme\.of\(context\)'),
    ];
    
    for (final pattern in constPatterns) {
      while (pattern.hasMatch(content)) {
        final match = pattern.firstMatch(content)!;
        content = content.replaceFirst(match.group(0)!, match.group(0)!.replaceFirst('const ', ''));
      }
    }

    if (content != original) {
      file.writeAsStringSync(content);
      filesFixed++;
      // Count approximate fixes
      final fixCount = original.length - content.replaceAll(RegExp(r'Theme\.of'), '').length + 
                        content.replaceAll(RegExp(r'Theme\.of'), '').length - original.replaceAll(RegExp(r'Theme\.of'), '').length;
    }
  }

  print('Dark mode migration complete! Fixed $filesFixed files.');
}
