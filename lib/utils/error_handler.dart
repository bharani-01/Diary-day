import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppError {
  final String title;
  final String message;
  final String suggestion;
  final String rawError;
  final ErrorType type;

  AppError({
    required this.title,
    required this.message,
    required this.suggestion,
    required this.rawError,
    required this.type,
  });
}

enum ErrorType { internet, database, timeout, unknown }

class ErrorHandler {
  static AppError handle(dynamic error) {
    String title = "Unexpected Error";
    String message = "Something went wrong while processing your request.";
    String suggestion = "Please try again later or contact support if the issue persists.";
    ErrorType type = ErrorType.unknown;
    String rawError = error.toString();

    if (error is SocketException) {
      title = "No Internet Connection";
      message = "We couldn't connect to the server. It seems your device is offline.";
      suggestion = "Check your Wi-Fi or mobile data settings and make sure you have a stable connection.";
      type = ErrorType.internet;
    } else if (error is TimeoutException) {
      title = "Request Timed Out";
      message = "The server is taking too long to respond.";
      suggestion = "This might be due to a slow internet connection. Please try again in a few moments.";
      type = ErrorType.timeout;
    } else if (error is PostgrestException) {
      type = ErrorType.database;
      if (error.code == '42501') {
        title = "Permission Denied";
        message = "You don't have permission to perform this action (RLS Policy Violation).";
        suggestion = "Make sure Row-Level Security policies are correctly configured in your Supabase dashboard.";
      } else if (error.code == '23505') {
        title = "Duplicate Record";
        message = "This record already exists in our system.";
        suggestion = "Try using a different unique identifier or check if you've already added this entry.";
      } else {
        title = "Database Error";
        message = "A problem occurred while communicating with the database.";
        suggestion = "Check your database schema and ensure all required fields are provided.";
      }
    } else if (error is StorageException) {
      title = "Storage Error";
      message = error.message;
      suggestion = "There was a problem uploading or retrieving your file. Please check your Supabase storage permissions.";
      type = ErrorType.database;
    } else if (error is AuthException) {
      title = "Authentication Error";
      message = error.message;
      suggestion = "Try logging out and logging back in, or check your account status.";
    } else if (rawError.contains('SupabaseClient') || rawError.contains('JWT')) {
      title = "Connection Config Error";
      message = "The application could not establish a secure connection to Supabase.";
      suggestion = "Verify your Project URL and Anon Key in the environment configuration.";
    }

    return AppError(
      title: title,
      message: message,
      suggestion: suggestion,
      rawError: rawError,
      type: type,
    );
  }
}
