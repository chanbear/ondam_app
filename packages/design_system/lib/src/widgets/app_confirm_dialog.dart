import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// Standardized confirm/cancel dialog — used ONLY for actions that are hard
/// to undo (account deletion, guardian disconnect, etc — ui-principles.md
/// "Confirmation" rule). Routine/reversible actions must not use this.
abstract final class AppConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = '확인',
    String cancelLabel = '취소',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style: TextStyle(color: destructive ? AppColors.error : null),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
