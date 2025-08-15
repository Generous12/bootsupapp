import 'package:flutter/material.dart';

class LoadingOverlayButton extends StatefulWidget {
  final Future<void> Function() onPressedLogic;
  final String text;
  final IconData? icon;

  final Color? backgroundColor;
  final Color? textColor;
  final Color? foregroundColor; // <-- nuevo parámetro opcional

  const LoadingOverlayButton({
    Key? key,
    required this.onPressedLogic,
    this.icon,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.foregroundColor, // <-- inicializar aquí
  }) : super(key: key);

  @override
  State<LoadingOverlayButton> createState() => _LoadingOverlayButtonState();
}

class _LoadingOverlayButtonState extends State<LoadingOverlayButton> {
  bool isLoading = false;

  Future<void> _handlePressed() async {
    setState(() => isLoading = true);
    await widget.onPressedLogic();
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final backgroundColor = widget.backgroundColor ??
        (isDark ? const Color(0xFF2D2D2D) : Colors.black);

    // Usamos foregroundColor si está definido, si no, fallback a textColor por defecto
    final textColor = widget.foregroundColor ??
        widget.textColor ??
        (isDark ? Colors.white : Colors.white);

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: isLoading,
          child: Opacity(
            opacity: isLoading ? 0.5 : 1,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handlePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                elevation: 5.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                minimumSize: const Size(double.infinity, 48.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: textColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 17.5,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isLoading)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 76, 76, 76),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
