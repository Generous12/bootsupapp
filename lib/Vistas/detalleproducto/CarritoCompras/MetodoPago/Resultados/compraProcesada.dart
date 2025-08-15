// ignore_for_file: unused_local_variable

import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/carritoService.dart';
import 'package:bootsup/Vistas/screensPrincipales/MainScreen.dart';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class CompraExitosaScreen extends StatefulWidget {
  final List<Map<String, dynamic>>
      carrito; // Carrito pasado desde la pantalla anterior
  final String direccionEntrega;

  const CompraExitosaScreen({
    super.key,
    required this.carrito,
    required this.direccionEntrega,
  });

  @override
  State<CompraExitosaScreen> createState() => _CompraExitosaScreenState();
}

class _CompraExitosaScreenState extends State<CompraExitosaScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ejecutarFinalizarCompra();
  }

  Future<void> _ejecutarFinalizarCompra() async {
    final carritoService = Provider.of<CarritoService>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await finalizarCompra(context);
      carritoService.limpiarCarrito();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> finalizarCompra(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final carritoService = context.read<CarritoService>();

      final carrito = carritoService.obtenerCarrito();
      if (carrito.isEmpty) {
        await showCustomDialog(
          context: context,
          title: 'ERROR',
          message: 'Su compra no  ha sido procesada',
          confirmButtonText: 'Cerrar',
        );
        setState(() => _isLoading = false);
        return;
      }
      final double total = carritoService.calcularTotal();
      final _userId = user.uid;

// Calcular total de descuentos (solo para mostrar o registro)
      final double totalDescuento = carrito.fold(0.0, (sum, item) {
        final double precioConDescuento = (item['precio'] is String)
            ? double.tryParse(item['precio']) ?? 0.0
            : (item['precio'] as num?)?.toDouble() ?? 0.0;

        final int cantidad = (item['cantidad'] is String)
            ? int.tryParse(item['cantidad']) ?? 1
            : (item['cantidad'] as int?) ?? 1;

        final double descuento = (item['descuento'] is String)
            ? double.tryParse(item['descuento']) ?? 0.0
            : (item['descuento'] as num?)?.toDouble() ?? 0.0;

        // Calcular precio original a partir del precio con descuento
        final double precioOriginal = descuento > 0
            ? precioConDescuento / (1 - descuento / 100)
            : precioConDescuento;

        // Valor descontado por unidad multiplicado por la cantidad
        final double valorDescuento =
            (precioOriginal - precioConDescuento) * cantidad;

        return sum + valorDescuento;
      });

      final double subtotal =
          total; // precio ya incluye descuentos si se aplicaron
      final double impuesto = subtotal * 0.04;
      final double totalFinal = subtotal + impuesto;

      final direccionEntrega =
          context.read<CarritoService>().direccionEntrega.trim();
      final storage = FirebaseStorage.instance;
      final List<Map<String, dynamic>> productosConImagen = [];

      for (var producto in carrito) {
        final nombreProducto = producto['nombreProducto'];

        int cantidadTotal = 0;
        if (producto['tallas'] != null && producto['tallas'] is Map) {
          cantidadTotal = (producto['tallas'] as Map)
              .values
              .fold<int>(0, (prev, e) => prev + (e as int));
        } else {
          cantidadTotal = producto['cantidad'] is int
              ? producto['cantidad']
              : int.tryParse(producto['cantidad'].toString()) ?? 1;
        }

        String? imagenUrl =
            (producto['imagenes'] != null && producto['imagenes'].isNotEmpty)
                ? producto['imagenes'][0]
                : null;
        String? imagenStorageUrl;
        if (imagenUrl != null) {
          final response = await http.get(Uri.parse(imagenUrl));
          if (response.statusCode == 200) {
            final bytes = response.bodyBytes;

            String storagePathCompra =
                'images/$_userId/Compras/${nombreProducto}_${DateTime.now().millisecondsSinceEpoch}.png';
            await storage.ref(storagePathCompra).putData(bytes);
            imagenStorageUrl =
                await storage.ref(storagePathCompra).getDownloadURL();
          } else {
            print('No se pudo descargar la imagen de $imagenUrl');
          }
        }

        final productoSnapshot = await FirebaseFirestore.instance
            .collection('productos')
            .where('nombreProducto', isEqualTo: nombreProducto)
            .limit(1)
            .get();

        if (productoSnapshot.docs.isNotEmpty) {
          final doc = productoSnapshot.docs.first;
          final cantidadActual = doc['cantidad'] ?? 0;
          final stockFinal = cantidadActual - cantidadTotal;
          await doc.reference
              .update({'cantidad': stockFinal < 0 ? 0 : stockFinal});
        }

        final dynamic precioRaw = producto['precio'];
        final dynamic descuentoRaw = producto['descuento'];

        final double precio = (precioRaw is String)
            ? double.tryParse(precioRaw) ?? 0.0
            : (precioRaw is num)
                ? precioRaw.toDouble()
                : 0.0;
//posible uso
        final double descuento = (descuentoRaw is String)
            ? double.tryParse(descuentoRaw) ?? 0.0
            : (descuentoRaw is num)
                ? descuentoRaw.toDouble()
                : 0.0;

        final double precioConDescuento = precio;
        final Map<String, dynamic> data = {
          'nombreProducto': producto['nombreProducto'],
          'precio': precioConDescuento,
          'categoria': producto['categoria'],
          'imagenCompraUrl': imagenStorageUrl,
        };

        if (producto['categoria'] == 'Ropa' ||
            producto['categoria'] == 'Calzado') {
          data['color'] = producto['color'];
          data['tallas'] = producto['tallas'];
        } else if (producto['categoria'] == 'Tecnologias' ||
            producto['categoria'] == 'Juguetes') {
          data['marca'] = producto['marca'];
          data['cantidad'] = cantidadTotal;
        } else {
          data['cantidad'] = cantidadTotal;
        }
        productosConImagen.add(data);
      }
      final Map<String, dynamic> compraData = {
        'usuarioId': _userId,
        'fecha': FieldValue.serverTimestamp(),
        'direccionEntrega': direccionEntrega,
        'empresaId': carrito.isNotEmpty ? carrito[0]['userid'] : null,
        'productos': productosConImagen,
        'subtotal': subtotal,
        'impuesto': impuesto,
        'descuento': totalDescuento,
        'total': totalFinal,
        'estado': 'No atendido',
      };

      await FirebaseFirestore.instance.collection('compras').add(compraData);

      await showCustomDialog(
        context: context,
        title: 'Éxito',
        message: 'Su compra ha sido procesada',
        confirmButtonText: 'Cerrar',
      );

      setState(() {
        carritoService.limpiarCarrito();
      });
    } catch (e) {
      print('Error al finalizar compra: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al realizar la compra')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF5F5F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 150,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '¡Compra realizada con éxito!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tu pedido se ha procesado correctamente. Gracias por confiar en nosotros.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[300] : Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        final user = FirebaseAuth.instance.currentUser;
                        Navigator.pushAndRemoveUntil(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => MainScreen(user: user),
                            transitionsBuilder: (_, animation, __, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut,
                                )),
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 300),
                          ),
                          (route) => false,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: Colors.orangeAccent.shade400,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.orangeAccent.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Volver al inicio',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
