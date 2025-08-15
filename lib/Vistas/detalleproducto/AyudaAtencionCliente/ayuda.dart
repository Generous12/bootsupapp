import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AyudaScreen extends StatefulWidget {
  const AyudaScreen({super.key});

  @override
  State<AyudaScreen> createState() => _AyudaMarketplaceScreenState();
}

class _AyudaMarketplaceScreenState extends State<AyudaScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left,
              color: colorScheme.onBackground, size: 25),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ayuda',
          style: TextStyle(
            fontSize: 23,
            color: colorScheme.onBackground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[300],
          ),
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildHelpCard(
              context: context,
              icon: Iconsax.info_circle,
              title: '¿Cómo funciona la app?',
              description:
                  'Nuestra plataforma conecta consumidores (B2C) y negocios (B2B) con empresas registradas dentro del marketplace. Puedes contactar, contratar o negociar directamente con proveedores de productos o servicios.',
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context: context,
              icon: Iconsax.message_question,
              title: '¿Qué tipo de contacto puedo tener?',
              description:
                  'Puedes chatear, agendar reuniones, recibir cotizaciones o consultar disponibilidad directamente desde la app.',
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context: context,
              icon: Iconsax.wallet_2,
              title: '¿Hay algún costo?',
              description:
                  'El registro es gratuito para usuarios. Algunas funciones avanzadas pueden requerir suscripción.',
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context: context,
              icon: Iconsax.building,
              title: '¿Cómo accedo al perfil empresarial?',
              description:
                  'Para utilizar funciones del perfil empresarial (si aplica), es necesario completar todos los datos obligatorios del registro, incluyendo información legal y de contacto. Esto permite validar tu identidad como empresa y acceder a herramientas específicas como estadísticas, gestión de productos o atención personalizada.',
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context: context,
              icon: Iconsax.security_safe,
              title: '¿Por qué es importante registrar datos correctos?',
              description:
                  'Los datos verificados aumentan tu visibilidad dentro del marketplace y permiten establecer confianza con los usuarios o potenciales clientes. Además, ciertas funciones están limitadas solo a cuentas con información válida.',
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              '¿Necesitas más ayuda?\nEscríbenos a soporte@tuapp.com',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? []
            : const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
        border: isDark ? Border.all(color: Colors.white12, width: 1) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onBackground,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onBackground.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
