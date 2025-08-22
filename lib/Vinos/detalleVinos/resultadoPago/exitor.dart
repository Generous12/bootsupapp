// ignore_for_file: unused_local_variable

import 'dart:io';
import 'dart:typed_data';
import 'package:bootsup/ModulosVinos/crritoServiceV.dart';
import 'package:bootsup/Vinos/screePrincipal/mainScreens.dart';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class CompraExitosaScreenVinos extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;
  final String direccionEntrega;

  const CompraExitosaScreenVinos({
    super.key,
    required this.carrito,
    required this.direccionEntrega,
  });

  @override
  State<CompraExitosaScreenVinos> createState() => _CompraExitosaScreenState();
}

class _CompraExitosaScreenState extends State<CompraExitosaScreenVinos> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ejecutarFinalizarCompra();
  }

  Future<void> _ejecutarFinalizarCompra() async {
    final carritoService =
        Provider.of<CarritoServiceVinos>(context, listen: false);
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

  Future<Uint8List> convertImageToWebP(File file, {int quality = 90}) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      format: CompressFormat.webp,
      quality: quality,
      minWidth: 1080,
      minHeight: 1080,
    );
    if (result == null) throw Exception('No se pudo convertir a WebP');
    return result;
  }

  Future<void> finalizarCompra(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final carritoService = context.read<CarritoServiceVinos>();
      final carrito = carritoService.obtenerCarrito();

      if (carrito.isEmpty) {
        await showCustomDialog(
          context: context,
          title: 'ERROR',
          message: 'Su compra no ha sido procesada',
          confirmButtonText: 'Cerrar',
        );
        setState(() => _isLoading = false);
        return;
      }

      final double total = carritoService.calcularTotal();
      final _userId = user.uid;

      // Calcular total de descuentos
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

        final double precioOriginal = descuento > 0
            ? precioConDescuento / (1 - descuento / 100)
            : precioConDescuento;

        final double valorDescuento =
            (precioOriginal - precioConDescuento) * cantidad;

        return sum + valorDescuento;
      });

      final double subtotal = total;
      final double impuesto = subtotal * 0.04;
      final double totalFinal = subtotal + impuesto;

      final direccionEntrega =
          context.read<CarritoServiceVinos>().direccionEntrega.trim();
      final storage = FirebaseStorage.instance;
      final List<Map<String, dynamic>> productosConImagen = [];

      for (var producto in carrito) {
        final nombreProducto = producto['nombreProducto'];
        final marca = producto['marca'];
        final volumen = producto['volumen'];

        int cantidadTotal = (producto['cantidad'] is int)
            ? producto['cantidad']
            : int.tryParse(producto['cantidad'].toString()) ?? 1;

        String? imagenUrl =
            (producto['imagenes'] != null && producto['imagenes'].isNotEmpty)
                ? producto['imagenes'][0]
                : null;
        String? imagenStorageUrl;

        if (imagenUrl != null) {
          try {
            final response = await http.get(Uri.parse(imagenUrl));
            if (response.statusCode == 200) {
              final tempDir = await getTemporaryDirectory();
              final tempFile = File(
                  '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.png');
              await tempFile.writeAsBytes(response.bodyBytes);

              // Convertir a WebP
              final webpBytes = await convertImageToWebP(tempFile, quality: 90);

              // Guardar en Firebase Storage
              String storagePathCompra =
                  'ClientesCompras/$_userId/Compras/${DateTime.now().millisecondsSinceEpoch}.webp';
              await storage.ref(storagePathCompra).putData(webpBytes);

              imagenStorageUrl =
                  await storage.ref(storagePathCompra).getDownloadURL();
            } else {
              print('No se pudo descargar la imagen de $imagenUrl');
            }
          } catch (e) {
            print('Error al procesar imagen: $e');
          }
        }

        final dynamic precioRaw = producto['precio'];
        final dynamic descuentoRaw = producto['descuento'];

        final double precio = (precioRaw is String)
            ? double.tryParse(precioRaw) ?? 0.0
            : (precioRaw is num)
                ? precioRaw.toDouble()
                : 0.0;

        final double descuento = (descuentoRaw is String)
            ? double.tryParse(descuentoRaw) ?? 0.0
            : (descuentoRaw is num)
                ? descuentoRaw.toDouble()
                : 0.0;

        final double precioConDescuento = precio;

        final Map<String, dynamic> data = {
          'nombreProducto': nombreProducto,
          'marca': marca,
          'volumen': volumen,
          'cantidad': cantidadTotal,
          'precio': precioConDescuento,
          'descuento': descuento,
          'imagenCompraUrl': imagenStorageUrl,
        };

        productosConImagen.add(data);
      }

      final Map<String, dynamic> compraData = {
        'usuarioId': _userId,
        'fecha': FieldValue.serverTimestamp(),
        'direccionEntrega': direccionEntrega,
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
    const Color primaryColor = Color(0xFFA30000); // rojo oscuro
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
              // ✅ Ícono principal con sombra
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.1),
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
                  Iconsax.tick_circle,
                  color: primaryColor,
                  size: 120,
                ),
              ),

              const SizedBox(height: 32),

              // ✅ Título
              Text(
                '¡Compra realizada!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? backgroundLight : Colors.black,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 16),

              // ✅ Subtítulo
              Text(
                'Tu pedido se procesó correctamente.\nGracias por confiar en nosotros.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: isDarkMode ? Colors.grey[300] : Colors.black54,
                ),
              ),

              const SizedBox(height: 50),

              // ✅ Botón moderno
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          final user = FirebaseAuth.instance.currentUser;
                          Navigator.pushAndRemoveUntil(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  MainScreenVinos(user: user),
                              transitionsBuilder: (_, animation, __, child) {
                                return FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeInOut,
                                  ),
                                  child: child,
                                );
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 350),
                            ),
                            (route) => false,
                          );
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
                  icon: const Icon(Iconsax.home_2),
                  label: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Volver al inicio',
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
