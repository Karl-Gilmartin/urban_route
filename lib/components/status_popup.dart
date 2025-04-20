import 'package:flutter/material.dart';
import 'package:urban_route/main.dart';

enum StatusType {
  success,
  error,
  warning,
}

class StatusPopup extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final Color? buttonColor;
  final StatusType type;

  StatusPopup({
    super.key,
    required this.type,
    String? title,
    required this.message,
    this.buttonText = 'OK',
    required this.onButtonPressed,
    this.buttonColor,
  }) : title = title ?? _getDefaultTitle(type);

  static String _getDefaultTitle(StatusType type) {
    switch (type) {
      case StatusType.success:
        return 'Success!';
      case StatusType.error:
        return 'Error';
      case StatusType.warning:
        return 'Warning';
    }
  }

  static Color _getIconColor(StatusType type) {
    switch (type) {
      case StatusType.success:
        return Colors.green;
      case StatusType.error:
        return Colors.red;
      case StatusType.warning:
        return Colors.orange;
    }
  }

  static Color _getBackgroundColor(StatusType type) {
    switch (type) {
      case StatusType.success:
        return Colors.green[50] ?? Colors.green.shade50;
      case StatusType.error:
        return Colors.red[50] ?? Colors.red.shade50;
      case StatusType.warning:
        return Colors.orange[50] ?? Colors.orange.shade50;
    }
  }

  static IconData _getIcon(StatusType type) {
    switch (type) {
      case StatusType.success:
        return Icons.check_circle;
      case StatusType.error:
        return Icons.error;
      case StatusType.warning:
        return Icons.warning;
    }
  }

  static void showSuccess({
    required BuildContext context,
    String? title,
    required String message,
    String buttonText = 'OK',
    required VoidCallback onButtonPressed,
    Color? buttonColor,
  }) {
    show(
      context: context,
      type: StatusType.success,
      title: title,
      message: message,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
      buttonColor: buttonColor,
    );
  }

  static void showError({
    required BuildContext context,
    String? title,
    required String message,
    String buttonText = 'OK',
    required VoidCallback onButtonPressed,
    Color? buttonColor,
  }) {
    show(
      context: context,
      type: StatusType.error,
      title: title,
      message: message,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
      buttonColor: buttonColor,
    );
  }

  static void showWarning({
    required BuildContext context,
    String? title,
    required String message,
    String buttonText = 'OK',
    required VoidCallback onButtonPressed,
    Color? buttonColor,
  }) {
    show(
      context: context,
      type: StatusType.warning,
      title: title,
      message: message,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
      buttonColor: buttonColor,
    );
  }

  static void show({
    required BuildContext context,
    required StatusType type,
    String? title,
    required String message,
    String buttonText = 'OK',
    required VoidCallback onButtonPressed,
    Color? buttonColor,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatusPopup(
          type: type,
          title: title,
          message: message,
          buttonText: buttonText,
          onButtonPressed: onButtonPressed,
          buttonColor: buttonColor,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor(type);
    final backgroundColor = _getBackgroundColor(type);
    final icon = _getIcon(type);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor ?? _getIconColor(type),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 