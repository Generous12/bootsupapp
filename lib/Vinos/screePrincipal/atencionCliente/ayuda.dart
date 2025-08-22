import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AyudaScreenVinos extends StatefulWidget {
  const AyudaScreenVinos({super.key});

  @override
  State<AyudaScreenVinos> createState() => _AyudaMarketplaceScreenState();
}

class _AyudaMarketplaceScreenState extends State<AyudaScreenVinos> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        centerTitle: true,
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
                  'La Casita del Pisco te permite explorar publicaciones en la pantalla de inicio y descubrir nuestros productos en la sección de compras. Desde allí puedes seleccionar lo que desees, añadirlo al carrito y pagarlo fácilmente usando Mercado Pago u otros métodos de pago habilitados.',
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context: context,
              icon: Iconsax.message_question,
              title: '¿Qué tipo de contacto puedo tener?',
              description:
                  'Si tienes dudas sobre un producto o tu compra, puedes chatear directamente con nuestro equipo desde la aplicación. Estamos listos para responder consultas, ayudarte en el proceso de compra o resolver cualquier inconveniente.',
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context: context,
              icon: Iconsax.wallet_2,
              title: '¿Cómo funcionan los pagos?',
              description:
                  'Actualmente utilizamos Mercado Pago como pasarela principal. Sin embargo, también puedes usar otros métodos de pago habilitados dentro de la app para mayor comodidad y seguridad en tus transacciones.',
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context: context,
              icon: Iconsax.document_text,
              title: '¿Recibo una boleta por mi compra?',
              description:
                  'Sí. Una vez completada tu compra, puedes descargar tu boleta desde el detalle de pedido. Además, puedes consultar el historial de compras para ver todos los detalles de tus transacciones pasadas.',
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context: context,
              icon: Iconsax.user_edit,
              title: '¿Puedo configurar mi cuenta?',
              description:
                  'En la sección de perfil puedes actualizar tus datos personales, dirección y medios de contacto. Esto asegura que recibas tus pedidos sin problemas y que podamos brindarte una atención personalizada.',
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context: context,
              icon: Iconsax.brush_4,
              title: '¿Se puede personalizar la app?',
              description:
                  'Sí. Desde configuración puedes elegir el tema de la aplicación para adaptarlo a tu estilo. Queremos que tu experiencia en La Casita del Pisco sea cómoda y a tu manera.',
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              '¿Necesitas más ayuda?\nEscríbenos a soporte@lacasitadelpisco.com',
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
