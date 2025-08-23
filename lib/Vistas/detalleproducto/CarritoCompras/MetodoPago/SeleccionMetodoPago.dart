import 'dart:convert';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/MetodoPago/Resultados/Error.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/MetodoPago/Resultados/Espera.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/MetodoPago/Resultados/ResultadosPago.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/MetodoPago/Resultados/compraProcesada.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/carritoService.dart';
import 'package:bootsup/widgets/ModernInfoCard/cartasreutilizbles.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

List<Map<String, dynamic>> mapCarritoAMercadoPagoSoloTotal(
    List<Map<String, dynamic>> carrito, int cantidadTotal) {
  // Tomar el precio final ya calculado en el carrito (sin volver a aplicar descuento)
  double subtotal = carrito.fold(0.0, (sum, producto) {
    double precioFinal = (producto['precio'] is String)
        ? double.tryParse(producto['precio']) ?? 0.0
        : (producto['precio'] ?? 0.0);

    int cantidad = (producto['cantidad'] is String)
        ? int.tryParse(producto['cantidad']) ?? 1
        : (producto['cantidad'] ?? 1);

    return sum + (precioFinal * cantidad);
  });

  // Impuesto del 4%
  double impuesto = subtotal * 0.04;

  // Total final
  double totalFinal = subtotal + impuesto;

  return [
    {
      "title": "Total",
      "quantity": cantidadTotal > 0 ? cantidadTotal : 1,
      "unit_price": totalFinal / (cantidadTotal > 0 ? cantidadTotal : 1),
      "currency_id": "PEN",
    }
  ];
}

class ElegirMetodoPagoScreen extends StatelessWidget {
  const ElegirMetodoPagoScreen({super.key});
  Future<void> _abrirCheckout(BuildContext context) async {
    final carritoService = Provider.of<CarritoService>(context, listen: false);
    final itemsParaPago = mapCarritoAMercadoPagoSoloTotal(
        carritoService.obtenerCarrito(), carritoService.obtenerCantidadTotal());
    final urlBackend = Uri.parse(
        'https://bootsupapp-production.up.railway.app/crear-preferencia');
    try {
      final response = await http.post(
        urlBackend,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'items': itemsParaPago}),
      );
      final data = jsonDecode(response.body);
      final initPointString = data['init_point'] as String?;
      final paymentId = data['preference_id'] as String?;
      if (initPointString == null ||
          initPointString.isEmpty ||
          paymentId == null) {
        print('Respuesta backend: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos de pago inválidos')),
        );
        return;
      }
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MetodoPagoResultadoScreen(preferenceUrl: initPointString),
        ),
      );
      String? estadoPago = resultado == null
          ? await verificarPagoBackend(paymentId)
          : resultado == 'success'
              ? 'approved'
              : resultado == 'failure'
                  ? 'rejected'
                  : 'pending';
      if (estadoPago == 'approved') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompraExitosaScreen(
              carrito: carritoService.obtenerCarrito(),
              direccionEntrega: carritoService.direccionEntrega,
            ),
          ),
        );
      } else if (estadoPago == 'rejected') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const CompraFallidoScreen()));
      } else if (estadoPago == 'pending') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const CompraPendienteScreen()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir la pasarela de pago: $e')),
      );
    }
  }

  Future<String?> verificarPagoBackend(String paymentId) async {
    try {
      final url = Uri.parse(
          'https://bootsupapp-production.up.railway.app/verificar-pago/$paymentId');
      final response = await http.get(url);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      return data['status'] as String?;
    } catch (e) {
      print('Error verificando pago: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 0,
        toolbarHeight: 48,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            color: theme.iconTheme.color,
            size: 25,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Método de pago',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 20,
            color: theme.textTheme.bodyLarge?.color,
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Text(
            'Selecciona una opción de pago segura para continuar con tu compra.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 24),
          MetodoPagoCard(
            titulo: 'Pagar con Mercado Pago',
            imagen: 'assets/images/yape.png',
            descripcion: 'Pago rápido y sin comisiones.',
            onTap: () => _abrirCheckout(context),
          ),
        ],
      ),
    );
  }
}
