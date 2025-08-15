import 'dart:io';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/carritoService.dart';
import 'package:bootsup/Vistas/screensPrincipales/MainScreen.dart';
import 'package:bootsup/widgets/DialogosAlert.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:bootsup/widgets/menuBotones/disenoButon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class MetodoPagoYapeScreen extends StatefulWidget {
  const MetodoPagoYapeScreen({super.key});

  @override
  State<MetodoPagoYapeScreen> createState() => _MetodoPagoYapeScreenState();
}

class _MetodoPagoYapeScreenState extends State<MetodoPagoYapeScreen> {
  final nombreController = TextEditingController();
  final emailController = TextEditingController();

  File? imagenComprobante;
  bool isUploading = false;
  Future<QuerySnapshot>? _metodoPagoFuture;
  String? empresaUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final carrito =
          Provider.of<CarritoService>(context, listen: false).obtenerCarrito();

      if (carrito.isNotEmpty && carrito.first.containsKey('userid')) {
        final userId = carrito.first['userid']?.toString().trim();
        setState(() {
          empresaUserId = userId;
          _metodoPagoFuture = FirebaseFirestore.instance
              .collection('MetodoPago')
              .where('userId', isEqualTo: userId)
              .orderBy('fechaCreacion', descending: true)
              .limit(1)
              .get();
        });
      } else {
        setState(() {
          empresaUserId = null;
        });
      }
    });
  }

  Future<void> descargarYAbrirArchivo(BuildContext context, String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();

        // Detectar el nombre real del archivo desde la URL o usar un timestamp
        final extension = url.split('.').last.toLowerCase().split('?').first;
        final fileName =
            'archivo_${DateTime.now().millisecondsSinceEpoch}.$extension';

        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        final result = await OpenFile.open(file.path);

        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No se pudo abrir el archivo.")),
          );
        }
      } else {
        throw Exception(
            'Error al descargar el archivo (código ${response.statusCode})');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir archivo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (empresaUserId == null) {
      return const Scaffold(
        body: Center(child: Text('No se puede identificar la empresa.')),
      );
    }

    return WillPopScope(
        onWillPop: () async {
          return !isUploading;
        },
        child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            onVerticalDragStart: (_) {},
            onVerticalDragUpdate: (_) {},
            behavior: HitTestBehavior.translucent,
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
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
                    size: 25,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () {
                    if (!isUploading) {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                    }
                  },
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/yape.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pago con Yape',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 20,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1.0),
                  child: Container(
                    height: 1.0,
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[300],
                  ),
                ),
              ),
              body: _metodoPagoFuture == null
                  ? const Center(child: CircularProgressIndicator())
                  : FutureBuilder<QuerySnapshot>(
                      future: _metodoPagoFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return const Center(
                              child: Text('Error cargando métodos de pago.'));
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No se ha registrado ningún método de pago.',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        }
                        final theme = Theme.of(context);
                        final isDarkMode = theme.brightness == Brightness.dark;
                        final data = docs.first.data() as Map<String, dynamic>;
                        final nombre = data['nombre'] ?? '';
                        final numero = data['numero'] ?? '';
                        final archivoUrl = data['archivoUrl'] ?? '';

                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nombre del receptor:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                nombre,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Número Yape:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      numero,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 20),
                                    tooltip: 'Copiar número',
                                    onPressed: () {
                                      Clipboard.setData(
                                          ClipboardData(text: numero));
                                    },
                                  ),
                                ],
                              ),
                              if (archivoUrl.toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: LoadingOverlayButton(
                                    icon: Icons.qr_code,
                                    text: 'Ver imagen o archivo',
                                    onPressedLogic: () async {
                                      setState(() {
                                        isUploading = true;
                                      });

                                      await descargarYAbrirArchivo(
                                          context, archivoUrl);

                                      setState(() {
                                        isUploading = false;
                                      });
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(height: 25),
                              Text(
                                'Después de hacer el pago, sube una imagen del comprobante para que podamos verificarlo.',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 15),
                              CustomTextField(
                                controller: nombreController,
                                hintText: "Ingresar nombre completo",
                                prefixIcon: Iconsax.user,
                                label: "Nombre completo",
                              ),
                              const SizedBox(height: 15),
                              CustomTextField(
                                controller: emailController,
                                hintText: "Ingresar correo electrónico",
                                prefixIcon: Iconsax.sms,
                                label: "Correo electrónico",
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: imagenComprobante == null
                                    ? OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                              color: Color(0xFFFFAF00),
                                              width: 1.4),
                                          foregroundColor:
                                              const Color(0xFFFFAF00),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: () async {
                                          final picker = ImagePicker();
                                          final pickedFile =
                                              await picker.pickImage(
                                                  source: ImageSource.gallery);
                                          if (pickedFile != null) {
                                            setState(() {
                                              imagenComprobante =
                                                  File(pickedFile.path);
                                            });
                                          }
                                        },
                                        icon: const Icon(Icons.upload_rounded),
                                        label: const Text(
                                          'Subir comprobante',
                                          style: TextStyle(fontSize: 17),
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 16),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: const Color(0xFFFFAF00),
                                              width: 1.4),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.check_circle,
                                                color: Colors.green, size: 22),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Comprobante subido',
                                              style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 0, 0, 0),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(width: 12),
                                            GestureDetector(
                                              onTap: () async {
                                                final picker = ImagePicker();
                                                final pickedFile =
                                                    await picker.pickImage(
                                                        source: ImageSource
                                                            .gallery);
                                                if (pickedFile != null) {
                                                  setState(() {
                                                    imagenComprobante =
                                                        File(pickedFile.path);
                                                  });
                                                } else {
                                                  setState(() =>
                                                      imagenComprobante = null);
                                                }
                                              },
                                              child: const Text(
                                                'Cambiar',
                                                style: TextStyle(
                                                  decoration:
                                                      TextDecoration.underline,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFFFAF00),
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: LoadingOverlayButton(
                                  text: "Procesar solicitud de compra",
                                  onPressedLogic: () async {
                                    if (imagenComprobante == null ||
                                        nombreController.text.trim().isEmpty ||
                                        emailController.text.trim().isEmpty) {
                                      showCustomDialog(
                                        context: context,
                                        title: 'Campos vacíos',
                                        message: 'Completa todos los campos',
                                        confirmButtonText: 'Cerrar',
                                      );
                                      return;
                                    }
                                    bool? result = await showCustomDialog(
                                      context: context,
                                      title: 'Procesar solicitud',
                                      message:
                                          '¿Estás seguro? Desea continuar.',
                                      confirmButtonText: 'Sí',
                                      cancelButtonText: 'No',
                                      confirmButtonColor: Colors.red,
                                      cancelButtonColor:
                                          const Color.fromARGB(255, 0, 0, 0),
                                    );

                                    if (result == true) {
                                      if (mounted) {
                                        if (!mounted) return;
                                        setState(() => isUploading = true);

                                        final carritoService =
                                            Provider.of<CarritoService>(context,
                                                listen: false);

                                        await subirComprobanteAFirebase(
                                          imagenComprobante: imagenComprobante!,
                                          empresaUserId: empresaUserId!,
                                          nombre: nombreController.text,
                                          correo: emailController.text,
                                          carritoService: carritoService,
                                          context: context,
                                          onSuccess: () {
                                            if (!mounted) return;
                                            carritoService.limpiarCarrito();
                                            setState(() => isUploading = false);
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const MainScreen(),
                                              ),
                                            );
                                          },
                                          onError: (error) {
                                            if (!mounted) return;
                                            setState(() => isUploading = false);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Error al subir: $error')),
                                            );
                                          },
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            )));
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

  Future<void> subirComprobanteAFirebase({
    required File imagenComprobante,
    required String empresaUserId,
    required String nombre,
    required String correo,
    required CarritoService carritoService,
    required BuildContext context,
    required VoidCallback onSuccess,
    required void Function(String) onError,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      // Ver cuántas compras tiene el usuario para nombrar la carpeta
      final comprasSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('compras')
          .get();

      final int numeroCompra = comprasSnapshot.docs.length + 1;
      final String carpetaCompra = 'Compra_$numeroCompra';

      final Uint8List webpImage = await convertImageToWebP(imagenComprobante);

      final storageRef = FirebaseStorage.instance.ref().child(
          'images/$userId/Compras/$carpetaCompra/Comprobante/${DateTime.now().millisecondsSinceEpoch}.webp');

      final uploadTask = await storageRef.putData(webpImage);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      final compraRef = await finalizarCompra(carritoService);
      await compraRef.collection('comprobante').add({
        'usuarioId': userId,
        'empresaUserId': empresaUserId,
        'nombre': nombre.trim(),
        'correo': correo.trim(),
        'comprobanteUrl': downloadUrl,
        'fechaCreacion': Timestamp.now(),
        'estado': 'pendiente',
        'compraId': compraRef.id,
        'motivo': 'Ninguno,'
      });

      onSuccess();
    } catch (e) {
      print('Error al subir comprobante: $e');
      onError(e.toString());
    }
  }

  Future<DocumentReference> finalizarCompra(
      CarritoService carritoService) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final carrito = carritoService.obtenerCarrito();
      final double total = carritoService.calcularTotal();
      final String _userId = user.uid;

      final double totalConDescuento = carrito.fold(0.0, (sum, item) {
        final double precio = (item['precio'] is String)
            ? double.tryParse(item['precio']) ?? 0.0
            : (item['precio'] is num)
                ? item['precio'].toDouble()
                : 0.0;

        final int cantidad = (item['cantidad'] is String)
            ? int.tryParse(item['cantidad']) ?? 1
            : (item['cantidad'] is int)
                ? item['cantidad']
                : 1;

        final double descuento = (item['descuento'] is String)
            ? double.tryParse(item['descuento']) ?? 0.0
            : (item['descuento'] is num)
                ? item['descuento'].toDouble()
                : 0.0;

        final double precioConDescuento = precio * (1 - descuento / 100);
        return sum + precioConDescuento * cantidad;
      });

      final double totalDescuento = total - totalConDescuento;
      final double subtotal = totalDescuento > 0 ? totalConDescuento : total;
      final double impuesto = subtotal * 0.04;
      final double totalFinal = subtotal + impuesto;

      final direccionEntrega = carritoService.direccionEntrega.trim();
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
        final userId = FirebaseAuth.instance.currentUser?.uid;
        final comprasSnapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('compras')
            .get();
        final int numeroCompra = comprasSnapshot.docs.length + 1;
        final String carpetaCompra = 'Compra_$numeroCompra';
        if (imagenUrl != null) {
          final response = await http.get(Uri.parse(imagenUrl));
          if (response.statusCode == 200) {
            final bytes = response.bodyBytes;
            String storagePathCompra =
                'images/$_userId/Compras/$carpetaCompra/${nombreProducto}_${DateTime.now().millisecondsSinceEpoch}.png';
            await storage.ref(storagePathCompra).putData(bytes);
            imagenStorageUrl =
                await storage.ref(storagePathCompra).getDownloadURL();
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

        final double precio = (producto['precio'] is String)
            ? double.tryParse(producto['precio']) ?? 0.0
            : (producto['precio'] is num)
                ? producto['precio'].toDouble()
                : 0.0;

        final double descuento = (producto['descuento'] is String)
            ? double.tryParse(producto['descuento']) ?? 0.0
            : (producto['descuento'] is num)
                ? producto['descuento'].toDouble()
                : 0.0;

        final double precioConDescuento = precio * (1 - descuento / 100);

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

      final compraData = {
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

      final compraRef = await FirebaseFirestore.instance
          .collection('compras')
          .add(compraData);

      carritoService.limpiarCarrito();
      return compraRef;
    } catch (e) {
      print('Error al finalizar compra: $e');
      throw Exception('Error al finalizar la compra');
    }
  }
}
