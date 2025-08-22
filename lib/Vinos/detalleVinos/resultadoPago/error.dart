import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CompraFallidoScreenVinos extends StatelessWidget {
  const CompraFallidoScreenVinos({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color(0xFFA30000); // rojo elegante
    const Color backgroundLight = Color(0xFFFAFAFA);
    const Color backgroundDark = Colors.black;

    return Scaffold(
      backgroundColor: isDarkMode ? backgroundDark : backgroundLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ❌ Ícono principal con efecto circular
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.08),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 25,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: const Icon(
                  Iconsax.close_circle, // icono moderno de error
                  color: primaryColor,
                  size: 120,
                ),
              ),

              const SizedBox(height: 32),

              // ⚠️ Título
              Text(
                'Pago fallido',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? backgroundLight : Colors.black,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 16),

              // 📄 Descripción
              Text(
                'Lo sentimos, tu pago no pudo ser procesado.\nIntenta nuevamente o utiliza otro método de pago.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: isDarkMode ? Colors.grey[300] : Colors.black54,
                ),
              ),

              const SizedBox(height: 50),

              // 🔙 Botón Volver
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: primaryColor.withOpacity(0.5),
                  ),
                  icon: const Icon(Iconsax.arrow_left),
                  label: const Text(
                    'Volver',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
