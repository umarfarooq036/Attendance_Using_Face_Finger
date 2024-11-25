import 'package:flutter/material.dart';

class SnackbarHelper {
  SnackbarHelper._(); // Private constructor to prevent instantiation

  static void showSnackBar(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info, // Default to 'info' type
    Duration duration = const Duration(seconds: 3),
  }) {
    Color backgroundColor;

    // Determine background color based on the type
    switch (type) {
      case SnackBarType.success:
        backgroundColor = Colors.green;
        break;
      case SnackBarType.error:
        backgroundColor = Colors.red;
        break;
      case SnackBarType.info:
      default:
        backgroundColor = Colors.blueGrey;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: 14.0),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating, // Makes it look like a toast
        margin: EdgeInsets.symmetric(
            horizontal: 20.0, vertical: 10.0), // Adds padding around
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Rounded corners
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }
}

enum SnackBarType {
  success,
  error,
  info,
}
