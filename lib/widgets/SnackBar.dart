// ignore_for_file: file_names

import 'package:flutter/material.dart';

class SnackBarUtil {
  static void mostrarSnackBarPersonalizado({
    required BuildContext context,
    required String mensaje,
    IconData icono = Icons.info,
    Color? colorFondo,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorFondo ??
            (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE)),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 0),
        content: Row(
          children: [
            Icon(
              icono,
              color: isDark
                  ? Colors.white
                  : const Color.fromARGB(255, 255, 255, 255),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(
                  color: isDark
                      ? Colors.white
                      : const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
