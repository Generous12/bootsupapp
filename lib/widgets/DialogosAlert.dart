import 'package:flutter/material.dart';

Future<dynamic> showCustomDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmButtonText = 'Aceptar',
  String? cancelButtonText,
  Color? confirmButtonColor,
  Color? cancelButtonColor,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 50, vertical: 24),
        backgroundColor: theme.dialogBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onBackground,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 17,
                  color: colorScheme.onBackground.withOpacity(0.87),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 14),

              /// Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (cancelButtonText != null)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: cancelButtonColor ??
                            colorScheme.secondary.withOpacity(0.8),
                      ),
                      child: Text(
                        cancelButtonText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pop(cancelButtonText != null ? true : null),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          confirmButtonColor ?? colorScheme.primary,
                    ),
                    child: Text(
                      confirmButtonText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
