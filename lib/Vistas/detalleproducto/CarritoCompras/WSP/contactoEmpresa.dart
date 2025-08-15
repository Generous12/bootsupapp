import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/carritoService.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactoEmpresaScreen1 extends StatefulWidget {
  final String userIdVisitante;
  final String empresaUserId;

  const ContactoEmpresaScreen1({
    super.key,
    required this.userIdVisitante,
    required this.empresaUserId,
  });

  @override
  State<ContactoEmpresaScreen1> createState() => _ContactoEmpresaScreenState();
}

class _ContactoEmpresaScreenState extends State<ContactoEmpresaScreen1> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController motivoController = TextEditingController();
  bool considerarCarrito = false;
  String? perfilEmpresaUrl;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    cargarNombreUsuario();
    cargarImagenEmpresa(widget.empresaUserId);
  }

  @override
  void dispose() {
    userController.dispose();
    motivoController.dispose();
    super.dispose();
    cargarNombreUsuario();
  }

  String construirMensajeWhatsApp(
    List<Map<String, dynamic>> productos,
    double totalSinDescuento,
    double totalConDescuento,
    double totalDescuento,
    double subtotal,
    double impuesto,
    double totalFinal,
    String nombre,
    String motivo,
  ) {
    String mensaje = '👤 *Nombre:* $nombre\n'
        '📝 *Motivo de contacto:* $motivo\n\n'
        '🛒 *Detalles del pedido solicitado:*\n\n';

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

      int cantidad = producto['cantidad'] is int
          ? producto['cantidad']
          : int.tryParse(producto['cantidad'].toString()) ?? 1;

      double descuento = producto['descuento'] is num
          ? producto['descuento'].toDouble()
          : double.tryParse(producto['descuento'].toString()) ?? 0.0;

      double precioFinal = precio * (1 - descuento / 100);

      mensaje += 'Precio unitario: S/ ${precio.toStringAsFixed(2)}\n';

      if (descuento > 0) {
        mensaje += 'Descuento: ${descuento.toStringAsFixed(0)}%\n';
        mensaje += 'Precio final: S/ ${precioFinal.toStringAsFixed(2)}\n';
      }

      mensaje += 'Cantidad: $cantidad\n';

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
      }

      mensaje += '\n';
    }

    mensaje += '🧾 *Resumen del pedido:*\n';
    mensaje +=
        'Subtotal (sin descuento): S/ ${totalSinDescuento.toStringAsFixed(2)}\n';

    if (totalDescuento > 0) {
      mensaje +=
          'Descuento total aplicado: -S/ ${totalDescuento.toStringAsFixed(2)}\n';
      mensaje += 'Subtotal con descuento: S/ ${subtotal.toStringAsFixed(2)}\n';
    }

    mensaje += 'Impuesto (4%): S/ ${impuesto.toStringAsFixed(2)}\n';
    mensaje += '💰 *Total a pagar:* S/ ${totalFinal.toStringAsFixed(2)}\n';
    mensaje += '\nGracias por su atención. 🙌';

    return mensaje;
  }

  Future<Map<String, dynamic>?> prepararDatosContacto() async {
    try {
      final visitante = await obtenerDatosUsuario(widget.userIdVisitante);
      return visitante;
    } catch (e) {
      debugPrint("Error al preparar datos del contacto: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> obtenerDatosUsuario(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return snapshot.exists ? snapshot.data() : null;
    } catch (e) {
      debugPrint("Error al obtener datos del usuario: $e");
      return null;
    }
  }

  String construirMensajeConsultaUsuario(
      String nombre, String email, String motivo) {
    return '''
Hola 👋, le saluda *$nombre*
📧 Mi correo electrónico es: $email

📝 Motivo del contacto: $motivo

Por favor, quedo atento(a) a su respuesta. ¡Gracias!
''';
  }

  void _contactarEmpresa(String telefonoE, String mensaje) async {
    try {
      if (!RegExp(r'^\d{7,15}$').hasMatch(telefonoE)) {
        debugPrint("Número de teléfono inválido");
        return;
      }

      final Uri url = Uri.parse(
          "https://wa.me/$telefonoE?text=${Uri.encodeComponent(mensaje)}");

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        debugPrint("No se pudo abrir WhatsApp");
      }
    } catch (e) {
      debugPrint("Error al contactar por WhatsApp: $e");
    }
  }

  Future<String?> _obtenerTelefonoDesdeFirebase(String userId) async {
    try {
      final data = await _fetchEmpresaData(userId);
      return data?['telefonoE']?.toString();
    } catch (e) {
      debugPrint("Error al obtener el teléfono: $e");
      return null;
    }
  }

  Future<void> cargarNombreUsuario() async {
    try {
      final visitante = await obtenerDatosUsuario(widget.userIdVisitante);
      if (visitante?['username'] != null) {
        userController.text = visitante!['username'];
      } else {
        debugPrint("Nombre de usuario no disponible.");
      }
    } catch (e) {
      debugPrint("Error al cargar el nombre del usuario: $e");
    }
  }

  Future<Map<String, dynamic>?> _fetchEmpresaData(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('empresa')
          .doc(userId)
          .get();
      return snapshot.exists ? snapshot.data() : null;
    } catch (e) {
      debugPrint("Error al obtener datos de empresa: $e");
      return null;
    }
  }

  Future<void> cargarImagenEmpresa(String userId) async {
    try {
      final data = await _fetchEmpresaData(userId);
      if (data != null && data['perfilEmpresa'] != null) {
        final String urlImagen = data['perfilEmpresa'];
        setState(() {
          perfilEmpresaUrl = urlImagen;
        });
      } else {
        debugPrint("La imagen de perfil de empresa no está disponible.");
      }
    } catch (e) {
      debugPrint("Error al cargar imagen de perfil de empresa: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final carritoService = Provider.of<CarritoService>(context);
    List<Map<String, dynamic>> carrito = carritoService.obtenerCarrito();

    return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAFAFA),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 40,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: Icon(
              Iconsax.arrow_left,
              size: 30,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
            onPressed: () {
              if (!_isLoading) {
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            'Contactar empresa',
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 5),
            Center(
              child: perfilEmpresaUrl != null
                  ? ClipOval(
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/images/empresa.png',
                        image: perfilEmpresaUrl!,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/empresa.png',
                            width: 160,
                            height: 160,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: const [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFAF00),
                            strokeWidth: 4,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¿Quieres contactar a esta empresa?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF142143),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Puedes enviarle un mensaje o consultar sus productos disponibles.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF60646C),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Serás redirigido al número de contacto de la empresa vía WhatsApp.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF5C5C5C),
                    height: 1.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            CustomTextField(
              controller: userController,
              hintText: "Ingrese un nombre de usuario o nombres completo",
              prefixIcon: Iconsax.user_add,
              label: "Nombre de usuario o nombres completos",
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: motivoController,
              hintText: 'Escribe el motivo del contacto',
              maxLines: 5,
              maxLength: 200,
              label: "Motivo del contacto",
              showCounter: false,
            ),
            const SizedBox(height: 15),
            SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Iconsax.send_1, color: Colors.white),
                  label: const Text(
                    'Contactar empresa',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  onPressed: () async {
                    final nombre = userController.text.trim();
                    final motivo = motivoController.text.trim();

                    if (nombre.isEmpty || motivo.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Por favor, completa todos los campos."),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    final telefono = await _obtenerTelefonoDesdeFirebase(
                        widget.empresaUserId);
                    if (telefono == null) {
                      print("No se pudo obtener el teléfono de la empresa.");
                      return;
                    }

                    final visitante = await prepararDatosContacto();
                    if (visitante == null) {
                      print(
                          "No se pudo obtener los datos del usuario visitante.");
                      return;
                    }

                    final email = visitante['email'] ?? 'Sin correo';
                    String mensaje;

                    if (considerarCarrito && carrito.isNotEmpty) {
                      for (var producto in carrito) {
                        if (producto['precio'] is String) {
                        } else if (producto['precio'] is double) {
                        } else if (producto['precio'] is int) {}

                        if (producto.containsKey('cantidad')) {}
                      }

                      // Calcular con descuentos
                      final double totalSinDescuento =
                          carrito.fold(0.0, (sum, item) {
                        final precio = item['precio'] is num
                            ? item['precio']
                            : double.tryParse(item['precio'].toString()) ?? 0.0;
                        final cantidad = item['cantidad'] ?? 1;
                        return sum + precio * cantidad;
                      });

                      final double totalConDescuento =
                          carrito.fold(0.0, (sum, item) {
                        final precio = item['precio'] is num
                            ? item['precio'].toDouble()
                            : double.tryParse(item['precio'].toString()) ?? 0.0;

                        final cantidad = item['cantidad'] is int
                            ? item['cantidad']
                            : int.tryParse(item['cantidad'].toString()) ?? 1;

                        final rawDescuento = item['descuento'];
                        final descuento = rawDescuento is num
                            ? rawDescuento.toDouble()
                            : double.tryParse(rawDescuento?.toString() ?? '') ??
                                0.0;

                        final precioFinal = precio * (1 - (descuento / 100));
                        return sum + precioFinal * cantidad;
                      });

                      final double totalDescuento =
                          totalSinDescuento - totalConDescuento;
                      final double subtotal = totalDescuento > 0
                          ? totalConDescuento
                          : totalSinDescuento;
                      final double impuesto = subtotal * 0.04;
                      final double totalFinal = subtotal + impuesto;

                      // Construir mensaje de WhatsApp
                      mensaje = construirMensajeWhatsApp(
                        carrito,
                        totalSinDescuento,
                        totalConDescuento,
                        totalDescuento,
                        subtotal,
                        impuesto,
                        totalFinal,
                        nombre,
                        motivo,
                      );
                    } else {
                      mensaje = construirMensajeConsultaUsuario(
                          nombre, email, motivo);
                    }

                    _contactarEmpresa(telefono, mensaje);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.black),
                    ),
                  ),
                )),
            const SizedBox(height: 5),
            carrito.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Considerar carrito para el contacto",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          StatefulBuilder(
                            builder: (context, setState) {
                              return Switch(
                                value: considerarCarrito,
                                activeColor: Color(0xFFFFAF00),
                                inactiveThumbColor: Colors.black,
                                inactiveTrackColor: Colors.black26,
                                onChanged: (bool value) {
                                  setState(() {
                                    considerarCarrito = value;
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
          ]),
        ));
  }
}
