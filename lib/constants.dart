import 'package:flutter/material.dart';

class AppConstants {
  static const String supabaseUrl = 'https://plfkyjmlhrqtqblprtbz.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsZmt5am1saHJxdHFibHBydGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyNzEyMzIsImV4cCI6MjA5Mjg0NzIzMn0.z-iGMGByqnBm9hoRyIGGmC7kJzH1C-3t5KD9tCOq2Pg';

  // Theme Colors (Teal Palette from Lacto Design System)
  static const Color primaryColor = Color(0xFF0F766E); // Teal
  static const Color secondaryColor = Color(0xFFDCFCE7); // Soft Green
  static const Color backgroundColor = Color(0xFFF7FAF8); // Off-White
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFBA1A1A);
  
  // Spacing
  static const double basePadding = 16.0;
  static const double containerPadding = 24.0;

  static InputDecoration inputDecoration(String label, [BuildContext? context]) {
    final fillColor = context != null ? Theme.of(context).inputDecorationTheme.fillColor ?? Colors.white : Colors.white;
    final borderColor = context != null ? Theme.of(context).dividerColor : Colors.grey.shade300;
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: fillColor,
    );
  }
}
