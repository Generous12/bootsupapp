// ignore_for_file: unused_local_variable

import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/MetodoPago/SeleccionMetodoPago.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/carritoService.dart';
import 'package:bootsup/Vistas/menuOpcionesPerfil/direccion.dart';
import 'package:bootsup/Vistas/menuOpcionesPerfil/dni.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:bootsup/widgets/menuBotones/disenoButon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class CarritoPage extends StatefulWidget {
  @override
  _CarritoPageState createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  bool _isLoading = false;

  final TextEditingController _direccionController = TextEditingController();
  final FocusNode _direccionFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final Color naranja = const Color(0xFFFFAF00);
  final Color grisClaro = const Color.fromARGB(255, 0, 0, 0);
  bool _requiereDNI = false;
  @override
  void initState() {
    super.initState();
    _validarDNI();
  }

  Future<void> _validarDNI() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final dni = userDoc.data()?['dni'];

    if (dni == null || dni.toString().isEmpty) {
      setState(() {
        _requiereDNI = true;
      });
    }
  }

//CORRECTO, CALCULA BIEN EL PRECIO FINAL
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
  void dispose() {
    _direccionController.dispose();
    super.dispose();
  }

/*
  String construirMensajeWhatsApp(
      List<Map<String, dynamic>> productos, double total) {
    String mensaje = '🛒 *Detalles de la compra:*\n\n';

    for (var producto in productos) {
      mensaje += '🔹 *${producto['nombreProducto']}*\n';
      mensaje += 'Categoría: ${producto['categoria']}\n';

      double precio = 0.0;
      if (producto['precio'] is String) {
        precio = double.tryParse(producto['precio']) ?? 0.0;
      } else if (producto['precio'] is double) {
        precio = producto['precio'];
      } else if (producto['precio'] is int) {
        precio = producto['precio'].toDouble();
      }

      mensaje += 'Precio: S/ ${precio.toStringAsFixed(2)}\n';

      if (producto['categoria'] == 'Ropa' ||
          producto['categoria'] == 'Calzado') {
        if (producto.containsKey('color')) {
          mensaje += 'Color: ${producto['color']}\n';
        }

        if (producto.containsKey('tallas')) {
          mensaje += 'Tallas:\n';
          final tallas = Map<String, int>.from(producto['tallas']);
          tallas.forEach((talla, cantidad) {
            mensaje += '- $talla: $cantidad\n';
          });
        }
      } else if (producto['categoria'] == 'Tecnologias' ||
          producto['categoria'] == 'Juguetes') {
        if (producto.containsKey('marca')) {
          mensaje += 'Marca: ${producto['marca']}\n';
        }
        if (producto.containsKey('cantidad')) {
          mensaje += 'Cantidad: ${producto['cantidad']}\n';
        }
      } else {
        if (producto.containsKey('cantidad')) {
          mensaje += 'Cantidad: ${producto['cantidad']}\n';
        }
      }

      mensaje += '\n';
    }

    mensaje += '💰 *Total a pagar:* S/ ${total.toStringAsFixed(2)}\n';
    mensaje += 'Gracias por su atención. 🙌';

    return mensaje;
  }

  void _contactarEmpresa(String telefono, String mensaje) async {
    final Uri url = Uri.parse(
        "https://wa.me/$telefonoE?text=${Uri.encodeComponent(mensaje)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print("No se pudo abrir WhatsApp");
    }
  }
*/
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final carritoService = Provider.of<CarritoService>(context);
    List<Map<String, dynamic>> carrito = carritoService.obtenerCarrito();
    final double total = carrito.fold(0.0, (sum, item) {
      final dynamic precioRaw = item['precio'];
      final dynamic cantidadRaw = item['cantidad'];

      final double precio = (precioRaw is String)
          ? double.tryParse(precioRaw) ?? 0.0
          : (precioRaw is num)
              ? precioRaw.toDouble()
              : 0.0;

      final int cantidad = (cantidadRaw is String)
          ? int.tryParse(cantidadRaw) ?? 1
          : (cantidadRaw is int)
              ? cantidadRaw
              : 1;

      return sum + precio * cantidad;
    });
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
    return WillPopScope(
        onWillPop: () async {
          return !_isLoading;
        },
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          onVerticalDragStart: (_) {},
          onVerticalDragUpdate: (_) {},
          behavior: HitTestBehavior.translucent,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              centerTitle: true,
              titleSpacing: 0,
              toolbarHeight: 35,
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
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            body: _requiereDNI
                ? Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Agrega tu DNI para continuar',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: theme.colorScheme.onBackground,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Para poder realizar compras, necesitamos que registres tu número de DNI.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 16,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => IdentidadScreen()),
                                  );
                                  _validarDNI();
                                },
                                icon: const Icon(Iconsax.edit_2),
                                label: const Text(
                                  'Agregar DNI ahora',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor:
                                      theme.colorScheme.onSecondary,
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : carrito.isEmpty
                    ? Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/carritovacio.png',
                                  width: 200,
                                  height: 200,
                                ),
                                const SizedBox(height: 16),
                                Text('Tu carrito está vacío',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: theme.textTheme.bodyLarge?.color,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      )
                    : DraggableScrollableSheet(
                        expand: true,
                        initialChildSize: 1.0,
                        minChildSize: 1.0,
                        maxChildSize: 1.0,
                        snap: true,
                        snapSizes: const [1.0],
                        controller: DraggableScrollableController(),
                        builder: (context, scrollController) {
                          return SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 498,
                                  child: ListView.builder(
                                    itemCount: carrito.length,
                                    itemBuilder: (context, index) {
                                      final producto = carrito[index];
                                      return Stack(
                                        children: [
                                          Card(
                                            color:
                                                theme.scaffoldBackgroundColor,
                                            elevation: 0,
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 1, horizontal: 5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              side: BorderSide(
                                                color: Colors.grey.shade300,
                                                width: 1,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(5.0),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  producto['imagenes'] !=
                                                              null &&
                                                          producto['imagenes']
                                                              .isNotEmpty
                                                      ? ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          child: Image.network(
                                                            producto['imagenes']
                                                                [0],
                                                            width: 109,
                                                            height: 109,
                                                            fit: BoxFit.cover,
                                                            loadingBuilder:
                                                                (context, child,
                                                                    loadingProgress) {
                                                              if (loadingProgress ==
                                                                  null)
                                                                return child;
                                                              return Container(
                                                                width: 109,
                                                                height: 109,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child:
                                                                    const CircularProgressIndicator(
                                                                  color: Color(
                                                                      0xFFFFAF00),
                                                                ),
                                                              );
                                                            },
                                                            errorBuilder:
                                                                (context, error,
                                                                    stackTrace) {
                                                              return Image
                                                                  .asset(
                                                                'assets/images/empresa.png',
                                                                width: 109,
                                                                height: 109,
                                                                fit: BoxFit
                                                                    .cover,
                                                              );
                                                            },
                                                          ),
                                                        )
                                                      : Image.asset(
                                                          'assets/images/empresa.png',
                                                          width: 109,
                                                          height: 109,
                                                          fit: BoxFit.cover,
                                                        ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          producto[
                                                                  'nombreProducto'] ??
                                                              'Producto',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 18.5,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        if (producto[
                                                                    'categoria'] ==
                                                                'Ropa' ||
                                                            producto[
                                                                    'categoria'] ==
                                                                'Calzado') ...[
                                                          if (producto[
                                                                      'tallas'] !=
                                                                  null &&
                                                              producto['tallas']
                                                                  is Map &&
                                                              (producto['tallas']
                                                                      as Map)
                                                                  .isNotEmpty)
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                SingleChildScrollView(
                                                                  scrollDirection:
                                                                      Axis.horizontal,
                                                                  child: Row(
                                                                    children: (producto['tallas']
                                                                            as Map)
                                                                        .map((key, value) => MapEntry(
                                                                            key
                                                                                .toString(),
                                                                            value))
                                                                        .entries
                                                                        .map<Widget>(
                                                                            (entry) {
                                                                      final talla =
                                                                          entry
                                                                              .key;
                                                                      final cantidad =
                                                                          entry
                                                                              .value;

                                                                      return Container(
                                                                        margin: const EdgeInsets
                                                                            .only(
                                                                            right:
                                                                                6),
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            horizontal:
                                                                                6,
                                                                            vertical:
                                                                                4),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color: isDark
                                                                              ? const Color(0xFF1E1E1E)
                                                                              : const Color.fromARGB(255, 255, 255, 255),
                                                                          borderRadius:
                                                                              BorderRadius.circular(8),
                                                                          border:
                                                                              Border.all(
                                                                            color: isDark
                                                                                ? Colors.white
                                                                                : const Color.fromARGB(118, 0, 0, 0),
                                                                          ),
                                                                        ),
                                                                        child:
                                                                            Row(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          children: [
                                                                            Text(
                                                                              '$talla: $cantidad',
                                                                              style: const TextStyle(fontSize: 15),
                                                                            ),
                                                                            const SizedBox(width: 4),
                                                                            GestureDetector(
                                                                              onTap: () {
                                                                                final carritoService = Provider.of<CarritoService>(context, listen: false);

                                                                                setState(() {
                                                                                  final tallaMap = Map<String, dynamic>.from(
                                                                                    (producto['tallas'] as Map).map(
                                                                                      (key, value) => MapEntry(key.toString(), value),
                                                                                    ),
                                                                                  );

                                                                                  if (tallaMap[talla] > 1) {
                                                                                    tallaMap[talla]--;
                                                                                  } else {
                                                                                    tallaMap.remove(talla);
                                                                                  }

                                                                                  producto['tallas'] = tallaMap;
                                                                                  producto['cantidad'] = (producto['cantidad'] ?? 0) - 1;

                                                                                  if (tallaMap.isEmpty) {
                                                                                    carritoService.eliminarProducto(index);
                                                                                  }
                                                                                });
                                                                              },
                                                                              child: const Icon(
                                                                                Icons.close,
                                                                                size: 17,
                                                                                color: Colors.redAccent,
                                                                              ),
                                                                            ),
                                                                            const Icon(Icons.swipe,
                                                                                size: 17,
                                                                                color: Colors.grey),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    }).toList(),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                        ] else if (producto[
                                                                    'categoria'] !=
                                                                'Ropa' &&
                                                            producto[
                                                                    'categoria'] !=
                                                                'Calzado')
                                                          Row(
                                                            children: [
                                                              Container(
                                                                width: 25,
                                                                height: 25,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .black,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                                child:
                                                                    IconButton(
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .remove,
                                                                      color: Colors
                                                                          .white),
                                                                  iconSize: 14,
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  constraints:
                                                                      const BoxConstraints(),
                                                                  onPressed:
                                                                      () {
                                                                    final carritoService = Provider.of<
                                                                            CarritoService>(
                                                                        context,
                                                                        listen:
                                                                            false);
                                                                    setState(
                                                                        () {
                                                                      if ((producto['cantidad'] ??
                                                                              1) >
                                                                          1) {
                                                                        producto[
                                                                            'cantidad']--;
                                                                      } else {
                                                                        carritoService
                                                                            .eliminarProducto(index);
                                                                      }
                                                                    });
                                                                  },
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        14.0),
                                                                child: Text(
                                                                  '${producto['cantidad']}',
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          18),
                                                                ),
                                                              ),
                                                              Container(
                                                                width: 25,
                                                                height: 25,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .black,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                                child:
                                                                    IconButton(
                                                                  icon: const Icon(
                                                                      Icons.add,
                                                                      color: Colors
                                                                          .white),
                                                                  iconSize: 14,
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  constraints:
                                                                      const BoxConstraints(),
                                                                  onPressed:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      producto[
                                                                              'cantidad'] =
                                                                          (producto['cantidad'] ?? 0) +
                                                                              1;
                                                                    });
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          )
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 85,
                                            right: 12,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 1),
                                              child: Row(
                                                children: () {
                                                  final precio =
                                                      double.tryParse(producto[
                                                                  'precio']
                                                              .toString()) ??
                                                          0.0;
                                                  final descuento =
                                                      double.tryParse(producto[
                                                                  'descuento']
                                                              .toString()) ??
                                                          0.0;

                                                  if (descuento > 0) {
                                                    return [
                                                      Text(
                                                        'S/ ${precio.toStringAsFixed(2)}',
                                                        style: theme.textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                          fontSize: 17,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: theme.textTheme
                                                              .bodyLarge?.color,
                                                        ),
                                                      ),
                                                    ];
                                                  } else {
                                                    return [
                                                      Text(
                                                        'S/ ${precio.toStringAsFixed(2)}',
                                                        style: theme.textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: theme.textTheme
                                                              .bodyLarge?.color,
                                                        ),
                                                      ),
                                                    ];
                                                  }
                                                }(),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                              top: 81,
                                              right: 335,
                                              child: Container(
                                                height: 30,
                                                width: 30,
                                                decoration: BoxDecoration(
                                                  color: Colors.black,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: IconButton(
                                                  icon: Icon(
                                                    Iconsax.trash,
                                                    size: 20,
                                                    color: Colors.white,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (!_isLoading) {
                                                        final carritoService =
                                                            Provider.of<
                                                                CarritoService>(
                                                          context,
                                                          listen: false,
                                                        );
                                                        carritoService
                                                            .eliminarProducto(
                                                                index);
                                                      }
                                                    });
                                                  },
                                                ),
                                              )),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                Column(children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildRowDetalle("Impuesto (10%)",
                                            "S/ ${impuesto.toStringAsFixed(2)}"),
                                        const SizedBox(height: 8),
                                        if (totalDescuento > 0)
                                          _buildRowDetalle(
                                            "Descuentos",
                                            "- S/ ${totalDescuento.toStringAsFixed(2)}",
                                            color: Colors.green[700],
                                          )
                                        else
                                          _buildRowDetalle(
                                            "Descuentos",
                                            "Sin descuento",
                                            color: Colors.grey[500],
                                          ),
                                        const SizedBox(height: 5),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total a pagar',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: theme
                                                    .textTheme.bodyLarge?.color,
                                              ),
                                            ),
                                            Text(
                                              'S/ ${totalFinal.toStringAsFixed(2)}',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: theme
                                                    .textTheme.bodyLarge?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Divider(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[700]
                                              : Colors.grey[300],
                                          thickness: 1,
                                          height: 18,
                                        ),
                                        const SizedBox(height: 10),
                                        Consumer<CarritoService>(
                                          builder:
                                              (context, carritoService, child) {
                                            return Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    _direccionController.text =
                                                        carritoService
                                                            .direccionEntrega;

                                                    showModalBottomSheet(
                                                      context: context,
                                                      isScrollControlled: true,
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      shape:
                                                          const RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.vertical(
                                                                top: Radius
                                                                    .circular(
                                                                        20)),
                                                      ),
                                                      builder: (context) =>
                                                          Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                          bottom: MediaQuery.of(
                                                                  context)
                                                              .viewInsets
                                                              .bottom,
                                                          top: 20,
                                                        ),
                                                        child:
                                                            _buildDireccionModal(
                                                                context),
                                                      ),
                                                    );
                                                  },
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        'Dirección de entrega',
                                                        style: theme.textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                          fontSize: 15,
                                                          color: theme.textTheme
                                                              .bodyLarge?.color,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 50),
                                                Expanded(
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Icon(
                                                      carritoService
                                                              .direccionEntrega
                                                              .isEmpty
                                                          ? Iconsax.close_circle
                                                          : Iconsax.tick_circle,
                                                      color: carritoService
                                                              .direccionEntrega
                                                              .isEmpty
                                                          ? Colors.red
                                                          : Colors.green,
                                                      size: 22,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        SizedBox(height: 15),
                                        Center(
                                          child: LoadingOverlayButton(
                                            text: 'Realizar Pago',
                                            backgroundColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.amber
                                                    : Colors.black,
                                            foregroundColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.black
                                                    : Colors.white,
                                            onPressedLogic: () async {
                                              if (carritoService
                                                  .direccionEntrega
                                                  .trim()
                                                  .isEmpty) {
                                                await showCustomDialog(
                                                  context: context,
                                                  title: 'Revisa tu formulario',
                                                  message:
                                                      'La dirección de entrega no puede estar vacía.',
                                                  confirmButtonText: 'Cerrar',
                                                );
                                                return;
                                              }

                                              navegarConSlideDerecha(context,
                                                  ElegirMetodoPagoScreen());
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ]),
                              ],
                            ),
                          );
                        }),
          ),
        ));
  }

  Widget _buildRowDetalle(String label, String value, {Color? color}) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildDireccionModal(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final carritoService = Provider.of<CarritoService>(context, listen: false);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Color(0xFFFFAF00),
                size: 40,
              ),
            );
          }

          final userData = snapshot.data!.data();
          final direccionUsuario = userData?['direccion'] ?? '';

          return StatefulBuilder(
            builder: (context, setState) {
              bool usarDireccionGuardada = direccionUsuario.isNotEmpty &&
                  direccionUsuario == carritoService.direccionEntrega;
              bool usarDireccionManual = !usarDireccionGuardada;

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Iconsax.home_2,
                              size: 19, color: Colors.black),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Usar mi dirección guardada',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (_, animation, __) =>
                                          DireccionScreen(),
                                      transitionsBuilder:
                                          (_, animation, __, child) {
                                        final tween = Tween(
                                                begin: const Offset(1.0, 0.0),
                                                end: Offset.zero)
                                            .chain(
                                                CurveTween(curve: Curves.ease));
                                        return SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 0),
                                  child: Text(
                                    'Actualizar direccion guardada',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          activeColor: Color(0xFFFFAF00),
                          inactiveThumbColor: Colors.black,
                          inactiveTrackColor: Colors.grey.shade300,
                          value: usarDireccionGuardada,
                          onChanged: (value) async {
                            setState(() {
                              usarDireccionGuardada = value;
                              usarDireccionManual = !value;
                            });

                            if (usarDireccionGuardada) {
                              final userId =
                                  FirebaseAuth.instance.currentUser!.uid;
                              final userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .get();
                              final direccion =
                                  userDoc.data()?['direccion'] ?? '';

                              if (direccion.isNotEmpty) {
                                carritoService
                                    .guardarDireccionEntrega(direccion);
                                Navigator.pop(context);
                              } else {
                                setState(() {
                                  usarDireccionGuardada = false;
                                  usarDireccionManual = true;
                                });

                                await showCustomDialog(
                                  context: context,
                                  title: 'Sin dirección',
                                  message:
                                      'No tienes una dirección registrada. ¿Deseas agregarla ahora?',
                                  confirmButtonText: 'Sí',
                                  cancelButtonText: 'No',
                                  confirmButtonColor: Colors.red,
                                  cancelButtonColor: Colors.blue,
                                ).then((confirmed) async {
                                  if (confirmed == true) {
                                    final resultado = await Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, animation, __) =>
                                            DireccionScreen(),
                                        transitionsBuilder:
                                            (_, animation, __, child) {
                                          final tween = Tween(
                                                  begin: const Offset(1.0, 0.0),
                                                  end: Offset.zero)
                                              .chain(CurveTween(
                                                  curve: Curves.ease));
                                          return SlideTransition(
                                            position: animation.drive(tween),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );

                                    if (resultado != null) {
                                      final userDoc = await FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .doc(userId)
                                          .get();
                                      final direccion =
                                          userDoc.data()?['direccion'] ?? '';

                                      if (direccion.isNotEmpty) {
                                        carritoService
                                            .guardarDireccionEntrega(direccion);
                                        Navigator.pop(context);
                                      } else {
                                        showCustomDialog(
                                          context: context,
                                          title: 'Error',
                                          message:
                                              'La dirección aún no ha sido registrada.',
                                          confirmButtonText: 'Ok',
                                        );
                                      }
                                    }
                                  }
                                });
                              }
                            } else {
                              carritoService.limpiardescripcion();
                            }
                          },
                        ),
                      ],
                    ),
                    Divider(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      thickness: 1,
                      height: 18,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Iconsax.edit_2,
                              size: 19, color: Colors.black),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ingresar nueva dirección',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        Switch(
                          activeColor: Color(0xFFFFAF00),
                          inactiveThumbColor: Colors.black,
                          inactiveTrackColor: Colors.grey.shade300,
                          value: usarDireccionManual,
                          onChanged: (value) {
                            setState(() {
                              usarDireccionManual = value;
                              usarDireccionGuardada = !value;
                            });

                            if (value) {
                              carritoService.limpiardescripcion();
                              _direccionController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                    if (usarDireccionManual) ...[
                      const SizedBox(height: 10),
                      CustomTextField(
                        focusNode: _direccionFocusNode,
                        controller: _direccionController,
                        hintText: 'Ej. Av. Los Incas 123, Ica - Perú',
                        maxLength: 200,
                        maxLines: 1,
                        label: "Dirección de domicilio",
                        showCounter: false,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor:
                                    theme.brightness == Brightness.dark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                              ),
                              child: Text(
                                "Cancelar",
                                style: TextStyle(
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                String nuevaDireccion =
                                    _direccionController.text.trim();
                                if (nuevaDireccion.isNotEmpty) {
                                  carritoService
                                      .guardarDireccionEntrega(nuevaDireccion);
                                  Navigator.pop(context);
                                } else {
                                  showCustomDialog(
                                    context: context,
                                    title: 'Campo vacío',
                                    message:
                                        'Por favor, ingresa una dirección.',
                                    confirmButtonText: 'Cerrar',
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Guardar",
                                      style: TextStyle(
                                          color: Color.fromARGB(255, 0, 0, 0)),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
