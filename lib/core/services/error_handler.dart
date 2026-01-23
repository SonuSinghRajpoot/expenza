import 'package:flutter/material.dart';

/// Centralized error handling service for user-friendly error messages
class ErrorHandler {
  /// Get user-friendly error message from exception
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred';
    
    final errorString = error.toString().toLowerCase();
    
    // Network errors
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('timeout')) {
      return 'Network error. Please check your internet connection.';
    }
    
    // API errors
    if (errorString.contains('api') || 
        errorString.contains('gemini') ||
        errorString.contains('429') || // Rate limit
        errorString.contains('401') || // Unauthorized
        errorString.contains('403')) { // Forbidden
      return 'Failed to analyze document. Please check your API key or try again later.';
    }
    
    // File errors
    if (errorString.contains('file') || 
        errorString.contains('permission') ||
        errorString.contains('access denied') ||
        errorString.contains('not found')) {
      return 'File access error. Please check permissions.';
    }
    
    // Database errors
    if (errorString.contains('database') || 
        errorString.contains('sql') ||
        errorString.contains('sqflite') ||
        errorString.contains('sqlcipher')) {
      return 'Data error. Please try again.';
    }
    
    // Validation errors
    if (errorString.contains('validation') || 
        errorString.contains('invalid') ||
        errorString.contains('required')) {
      return 'Invalid input. Please check your data and try again.';
    }
    
    // Generic fallback
    return 'An error occurred. Please try again.';
  }
  
  /// Show error snackbar
  static void showError(BuildContext context, dynamic error) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getUserFriendlyMessage(error)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  /// Show error dialog (for critical errors)
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
  }) async {
    if (!context.mounted) return;
    
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Error'),
        content: Text(getUserFriendlyMessage(error)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
