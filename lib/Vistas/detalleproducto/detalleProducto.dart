import 'dart:ui';

import 'package:bootsup/Vista/EmpresaVista/GestionEmpresaPubli/gestionProductos.dart';
import 'package:bootsup/Vista/EmpresaVista/PerfilEmpresa.dart';
import 'package:bootsup/Vista/EmpresaVista/VisitasPerfilYPublicaciones/VisitaPerfil.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/Badges.dart';
import 'package:bootsup/Vistas/detalleproducto/CarritoCompras/carritoService.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:bootsup/widgets/BotonesSeleccionables.dart';
import 'package:bootsup/widgets/SnackBar.dart';
import 'package:bootsup/widgets/cajadetexto.dart';
import 'package:bootsup/widgets/menuBotones/disenoButon.dart';
import 'package:bootsup/widgets/ratingEstrella/rating.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class DetalleProductoPage extends StatefulWidget {
  final Map producto;

  final bool desdeVisitaperfilScreen;
  final bool desdeVisitaperfilEmpresa;
  final bool desdeVisitacarrito;

  DetalleProductoPage({
    required this.producto,
    this.desdeVisitaperfilScreen = false,
    this.desdeVisitaperfilEmpresa = false,
    this.desdeVisitacarrito = false,
  });

  @override
  _DetalleProductoPageState createState() => _DetalleProductoPageState();
}

class _DetalleProductoPageState extends State<DetalleProductoPage> {
  late List<String> imagenes;
  List<String> _tallasSeleccionadas = [];
  late PageController _pageController;
  bool _mostrarBoton = false;
  int _cantidadSeleccionada = 1;
  List<Map<String, dynamic>> _empresas = [];
  bool expandido = false;
  final TextEditingController _comentarioController = TextEditingController();
  double _rating = 0.0;
  final FocusNode _focusNode = FocusNode();

  Future<void> _fetchEmpresas() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('empresa').get();

      final empresasCargadas = snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'userid': data['userid']?.toString() ?? '',
          'nombre': data['nombre']?.toString() ?? 'Nombre no disponible',
          'perfilEmpresa': data['perfilEmpresa']?.toString() ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _empresas = empresasCargadas;
        });
      }

      debugPrint('Empresas cargadas: ${_empresas.length}');
    } catch (e) {
      debugPrint('Error al cargar empresas: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    imagenes = List<String>.from(widget.producto['imagenes'] ?? []);
    _pageController = PageController();
    _fetchEmpresas();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _mostrarBoton = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double precioOriginal =
        double.tryParse(widget.producto['precio'].toString()) ?? 0.0;
    final double descuento =
        double.tryParse(widget.producto['descuento']?.toString() ?? '0') ?? 0.0;
    final bool hayDescuento = descuento > 0;
    final double precioFinal =
        hayDescuento ? precioOriginal * (1 - descuento / 100) : precioOriginal;
    final isCurrentUser =
        widget.producto['userid'] == FirebaseAuth.instance.currentUser?.uid;
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            _mostrarBoton = false;
          });
        },
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Stack(children: [
              SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0.0, vertical: 0.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
                                borderRadius: BorderRadius.circular(25),
                                shadowColor: Colors.black.withOpacity(0.6),
                                child: Hero(
                                  tag: 'productovista_${widget.producto['id']}',
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: ClipRRect(
                                      child: Stack(
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          imagenes.isNotEmpty
                                              ? PageView.builder(
                                                  controller: _pageController,
                                                  itemCount: imagenes.length,
                                                  onPageChanged: (index) {
                                                    setState(() {});
                                                  },
                                                  itemBuilder:
                                                      (context, index) {
                                                    final imageUrl =
                                                        imagenes[index];

                                                    return imageUrl
                                                            .toString()
                                                            .isNotEmpty
                                                        ? Image.network(
                                                            imageUrl,
                                                            fit: BoxFit.cover,
                                                            width:
                                                                double.infinity,
                                                            loadingBuilder:
                                                                (context, child,
                                                                    loadingProgress) {
                                                              if (loadingProgress ==
                                                                  null)
                                                                return child;
                                                              return Center(
                                                                child: LoadingAnimationWidget
                                                                    .staggeredDotsWave(
                                                                  color: Color(
                                                                      0xFFFFAF00),
                                                                  size: 50,
                                                                ),
                                                              );
                                                            },
                                                            errorBuilder:
                                                                (context, error,
                                                                    stackTrace) {
                                                              return Image
                                                                  .asset(
                                                                'assets/images/empresa.png',
                                                                fit: BoxFit
                                                                    .cover,
                                                                width: double
                                                                    .infinity,
                                                              );
                                                            },
                                                          )
                                                        : Image.asset(
                                                            'assets/images/empresa.png',
                                                            fit: BoxFit.cover,
                                                            width:
                                                                double.infinity,
                                                          );
                                                  },
                                                )
                                              : Container(
                                                  color: Colors.grey[300]),
                                          Positioned(
                                            top: 40,
                                            left: 16,
                                            child: Builder(
                                              builder: (context) {
                                                final isDark = Theme.of(context)
                                                        .brightness ==
                                                    Brightness.dark;
                                                return ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: BackdropFilter(
                                                    filter: ImageFilter.blur(
                                                        sigmaX: 6, sigmaY: 6),
                                                    child: Material(
                                                      color: isDark
                                                          ? Colors.black
                                                              .withOpacity(0.4)
                                                          : Colors.black
                                                              .withOpacity(0.4),
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        onTap: () {
                                                          if (Navigator.canPop(
                                                              context)) {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          }
                                                        },
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(10),
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.3),
                                                                blurRadius: 6,
                                                                offset:
                                                                    const Offset(
                                                                        0, 2),
                                                              )
                                                            ],
                                                          ),
                                                          child: const Icon(
                                                            Iconsax.arrow_left,
                                                            size: 24,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 12,
                                            child: SmoothPageIndicator(
                                              controller: _pageController,
                                              count: imagenes.length,
                                              effect: ScaleEffect(
                                                activeDotColor:
                                                    Color(0xFFFFAF00),
                                                dotColor: Colors.grey.shade400,
                                                dotHeight: 8,
                                                dotWidth: 8,
                                                spacing: 6,
                                                scale: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.producto['nombre'] ??
                                        widget.producto['nombreProducto'] ??
                                        'Sin nombre',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  ratingResumen(widget.producto['id']),
                                  SizedBox(height: 10),
                                  Text(
                                    widget.producto['descripcion'] ??
                                        widget.producto['descripcion'] ??
                                        'Sin descripcion',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 18),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (hayDescuento)
                                            Text(
                                              'S/ ${precioOriginal.toStringAsFixed(2)}',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontSize: 15,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color: theme
                                                    .textTheme.bodyLarge?.color,
                                              ),
                                            ),
                                          Text(
                                            'S/ ${precioFinal.toStringAsFixed(2)}',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold,
                                              color: theme
                                                  .textTheme.bodyLarge?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (hayDescuento)
                                        Text(
                                          '${descuento.toStringAsFixed(0)}% OFF',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (widget.desdeVisitaperfilEmpresa) ...[
                                    SizedBox(height: 20),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey.shade900
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Gestiona tus productos',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14.5,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.color,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Presiona sobre el botón para empezar a actualizar la información del producto.',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.grey.shade400
                                                        : Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: LoadingOverlayButton(
                                        text: 'Gestionar producto',
                                        onPressedLogic: () async {
                                          navegarConSlideDerecha(
                                              context, Gestionproductos());
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                  ],
                                  if ((widget.desdeVisitaperfilScreen &&
                                      !widget.desdeVisitaperfilEmpresa)) ...[
                                    buildCamposAdicionales(),
                                    SizedBox(height: 20),
                                    CantidadSelectorHorizontal(
                                      cantidadSeleccionada:
                                          _cantidadSeleccionada,
                                      onSeleccionar: (nuevaCantidad) {
                                        setState(() {
                                          _cantidadSeleccionada = nuevaCantidad;
                                        });
                                      },
                                    ),
                                    SizedBox(height: 20),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 0.0),
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  String categoria =
                                                      widget.producto[
                                                              'categoria'] ??
                                                          '';

                                                  if ((categoria == 'Ropa' ||
                                                          categoria ==
                                                              'Calzado') &&
                                                      _tallasSeleccionadas
                                                          .isEmpty) {
                                                    SnackBarUtil
                                                        .mostrarSnackBarPersonalizado(
                                                      context: context,
                                                      mensaje:
                                                          'Debes seleccionar al menos una talla',
                                                      icono: Icons.close,
                                                      colorFondo:
                                                          const Color.fromARGB(
                                                              255, 0, 0, 0),
                                                    );
                                                    return;
                                                  }

                                                  Map<String, dynamic>
                                                      productoParaCarrito;

                                                  if (categoria == 'Ropa' ||
                                                      categoria == 'Calzado') {
                                                    String tallasConcatenadas =
                                                        _tallasSeleccionadas
                                                            .join(', ');
                                                    String subTextoTalla = '';

                                                    if ((widget.producto[
                                                                        'tipoPrenda'] ??
                                                                    '')
                                                                .toLowerCase() ==
                                                            'pantalon' &&
                                                        _tallasSeleccionadas
                                                            .isNotEmpty) {
                                                      subTextoTalla =
                                                          convertirTallaPantalonACintura(
                                                              _tallasSeleccionadas
                                                                  .first);
                                                      tallasConcatenadas +=
                                                          ' (Cintura: $subTextoTalla)';
                                                    }

                                                    productoParaCarrito = {
                                                      'nombreProducto':
                                                          widget.producto[
                                                              'nombreProducto'],
                                                      'descripcion':
                                                          widget.producto[
                                                              'descripcion'],
                                                      'precio':
                                                          precioFinal, // <-- precio con descuento aplicado
                                                      'imagenes': widget
                                                          .producto['imagenes'],
                                                      'categoria':
                                                          widget.producto[
                                                              'categoria'],
                                                      'cantidad':
                                                          _cantidadSeleccionada,
                                                      'descuento': descuento,
                                                      'talla':
                                                          tallasConcatenadas,
                                                      if (widget.producto
                                                          .containsKey('color'))
                                                        'color': widget
                                                            .producto['color'],
                                                      if (widget.producto
                                                          .containsKey('marca'))
                                                        'marca': widget
                                                            .producto['marca'],
                                                      if (widget.producto
                                                          .containsKey(
                                                              'userid'))
                                                        'userid': widget
                                                            .producto['userid'],
                                                    };
                                                  } else if (categoria ==
                                                      'Juguetes') {
                                                    productoParaCarrito = {
                                                      'nombreProducto':
                                                          widget.producto[
                                                              'nombreProducto'],
                                                      'descripcion':
                                                          widget.producto[
                                                              'descripcion'],
                                                      'precio': precioFinal,
                                                      'imagenes': widget
                                                          .producto['imagenes'],
                                                      'categoria':
                                                          widget.producto[
                                                              'categoria'],
                                                      'cantidad':
                                                          _cantidadSeleccionada,
                                                      'descuento': descuento,
                                                      'marca': widget
                                                          .producto['marca'],
                                                      if (widget.producto
                                                          .containsKey(
                                                              'userid'))
                                                        'userid': widget
                                                            .producto['userid'],
                                                    };
                                                  } else {
                                                    productoParaCarrito = {
                                                      'nombreProducto':
                                                          widget.producto[
                                                              'nombreProducto'],
                                                      'descripcion':
                                                          widget.producto[
                                                              'descripcion'],
                                                      'precio': precioFinal,
                                                      'imagenes': widget
                                                          .producto['imagenes'],
                                                      'categoria':
                                                          widget.producto[
                                                              'categoria'],
                                                      'cantidad':
                                                          _cantidadSeleccionada,
                                                      'descuento': descuento,
                                                      if (widget.producto
                                                          .containsKey('color'))
                                                        'color': widget
                                                            .producto['color'],
                                                      if (widget.producto
                                                          .containsKey('marca'))
                                                        'marca': widget
                                                            .producto['marca'],
                                                      if (widget.producto
                                                          .containsKey(
                                                              'userid'))
                                                        'userid': widget
                                                            .producto['userid'],
                                                    };
                                                  }

                                                  final carrito = Provider.of<
                                                          CarritoService>(
                                                      context,
                                                      listen: false);
                                                  carrito.agregarProducto(
                                                      productoParaCarrito);

                                                  SnackBarUtil
                                                      .mostrarSnackBarPersonalizado(
                                                    context: context,
                                                    mensaje:
                                                        'Producto(s) agregado(s) al carrito',
                                                    icono: Icons.check_circle,
                                                    colorFondo:
                                                        const Color.fromARGB(
                                                            255, 0, 0, 0),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 9),
                                                  backgroundColor:
                                                      Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.amber
                                                          : Colors.black,
                                                  foregroundColor:
                                                      Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.black
                                                          : Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(width: 5),
                                                    Text(
                                                      'Agregar al carrito ',
                                                      style: TextStyle(
                                                          color: theme
                                                              .scaffoldBackgroundColor,
                                                          fontSize: 18),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 2),
                                          IconoCarritoConBadge(
                                            usarEstiloBoton: true,
                                            altura: 48,
                                            iconSize: 22,
                                            fondoColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.amber
                                                    : Colors.black,
                                            iconColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.black
                                                    : Colors.white,
                                            borderRadius: 8,
                                          ),
                                        ]),
                                    SizedBox(height: 15),
                                    Divider(
                                      thickness: 1.5,
                                      color: const Color.fromARGB(
                                          255, 225, 225, 225),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 0.0, vertical: 12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Danos tu opinión",
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 10),

                                              // ⭐ RATING BAR
                                              RatingBar.builder(
                                                initialRating: _rating,
                                                minRating: 1,
                                                direction: Axis.horizontal,
                                                allowHalfRating: true,
                                                itemCount: 5,
                                                itemPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 3.0),
                                                itemBuilder: (context, _) =>
                                                    const Icon(
                                                  Iconsax.star,
                                                  color: Colors.amber,
                                                ),
                                                onRatingUpdate: (rating) {
                                                  _rating = rating;
                                                },
                                              ),
                                              const SizedBox(height: 12),

                                              // 💬 CAMPO DE TEXTO
                                              CustomTextField(
                                                controller:
                                                    _comentarioController,
                                                focusNode: _focusNode,
                                                label: "Comentario",
                                                hintText:
                                                    "Escribe tu opinión...",
                                                maxLength: 500,
                                                minLines: 1,
                                                maxLines: 8,
                                                showCounter: false,
                                              ),
                                              if (_mostrarBoton)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 10.0),
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      onPressed: () async {
                                                        final comentario =
                                                            _comentarioController
                                                                .text
                                                                .trim();
                                                        final user =
                                                            FirebaseAuth
                                                                .instance
                                                                .currentUser;

                                                        if (comentario
                                                                .isEmpty ||
                                                            user == null ||
                                                            _rating == 0.0)
                                                          return;

                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'productos')
                                                            .doc(widget
                                                                .producto['id'])
                                                            .collection(
                                                                'comentarios')
                                                            .add({
                                                          'usuarioId': user.uid,
                                                          'comentario':
                                                              comentario,
                                                          'rating': _rating,
                                                          'timestamp': FieldValue
                                                              .serverTimestamp(),
                                                        });

                                                        _comentarioController
                                                            .clear();
                                                        _rating = 0.0;
                                                        setState(() {
                                                          _mostrarBoton = false;
                                                        });

                                                        SnackBarUtil
                                                            .mostrarSnackBarPersonalizado(
                                                          context: context,
                                                          mensaje:
                                                              'Comentario subido con éxito',
                                                          icono: Icons
                                                              .check_circle,
                                                          colorFondo:
                                                              Colors.black,
                                                        );
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 9),
                                                        backgroundColor: Theme.of(
                                                                        context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? const Color(
                                                                0xFF2C2C2C)
                                                            : Colors.black,
                                                        foregroundColor:
                                                            Colors.white,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        "Enviar comentario",
                                                        style: TextStyle(
                                                            fontSize: 18),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(height: 24),

                                              Text(
                                                "Valoracion y comentarios",
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.textTheme
                                                      .bodyLarge?.color,
                                                ),
                                              ),
                                              const SizedBox(height: 6),

                                              Text(
                                                "Lee lo que otros usuarios opinan sobre este producto. Sus experiencias pueden ayudarte a decidir mejor tu compra.",
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontSize: 13,
                                                  height: 1.4,
                                                  color: theme.textTheme
                                                      .bodyLarge?.color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // 📝 LISTA DE COMENTARIOS
                                        StreamBuilder<QuerySnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('productos')
                                              .doc(widget.producto['id'])
                                              .collection('comentarios')
                                              .orderBy('timestamp',
                                                  descending: true)
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                              return Center(
                                                child: LoadingAnimationWidget
                                                    .staggeredDotsWave(
                                                  color: Color(0xFFFFAF00),
                                                  size: 50,
                                                ),
                                              );
                                            }

                                            final comentarios =
                                                snapshot.data!.docs;

                                            if (comentarios.isEmpty) {
                                              return const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 0.0,
                                                    vertical: 12),
                                                child: Text(
                                                    "Aún no hay comentarios."),
                                              );
                                            }

                                            return Column(
                                              children: List.generate(
                                                  comentarios.length, (index) {
                                                final data =
                                                    comentarios[index].data()
                                                        as Map<String, dynamic>;
                                                final comentario =
                                                    data['comentario'] ?? '';
                                                final rating =
                                                    data['rating'] ?? 0.0;
                                                final usuarioId =
                                                    data['usuarioId'] ?? '';
                                                final timestamp =
                                                    data['timestamp']
                                                        as Timestamp?;
                                                final fecha =
                                                    timestamp?.toDate() ??
                                                        DateTime.now();
                                                final fechaFormateada =
                                                    "${fecha.day} ${mesAbreviado(fecha.month)} ${fecha.year}";

                                                return FutureBuilder<
                                                    DocumentSnapshot>(
                                                  future: FirebaseFirestore
                                                      .instance
                                                      .collection('users')
                                                      .doc(usuarioId)
                                                      .get(),
                                                  builder:
                                                      (context, userSnapshot) {
                                                    if (!userSnapshot.hasData)
                                                      return const SizedBox();

                                                    final userData =
                                                        userSnapshot.data!
                                                                .data()
                                                            as Map<String,
                                                                dynamic>?;
                                                    final username = userData?[
                                                            'username'] ??
                                                        'Usuario desconocido';
                                                    final profileImageUrl =
                                                        userData?[
                                                            'profileImageUrl'];

                                                    return Padding(
                                                      padding: EdgeInsets.only(
                                                        left: 0,
                                                        right: 0,
                                                        top: index == 0 ? 0 : 6,
                                                        bottom: 6,
                                                      ),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                CircleAvatar(
                                                                  radius: 18,
                                                                  backgroundImage: profileImageUrl !=
                                                                          null
                                                                      ? NetworkImage(
                                                                          profileImageUrl)
                                                                      : null,
                                                                  child: profileImageUrl ==
                                                                          null
                                                                      ? const Icon(
                                                                          Iconsax
                                                                              .user,
                                                                        )
                                                                      : null,
                                                                ),
                                                                const SizedBox(
                                                                    width: 10),
                                                                Expanded(
                                                                  child: Text(
                                                                    username,
                                                                    style:
                                                                        const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  fechaFormateada,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                            .grey[
                                                                        500],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                                height: 6),
                                                            RatingBarIndicator(
                                                              rating: (rating
                                                                      as num)
                                                                  .toDouble(),
                                                              itemBuilder:
                                                                  (context,
                                                                          _) =>
                                                                      const Icon(
                                                                Iconsax.star,
                                                                color: Colors
                                                                    .amber,
                                                              ),
                                                              itemCount: 5,
                                                              itemSize: 22,
                                                            ),
                                                            const SizedBox(
                                                                height: 10),
                                                            Text(
                                                              comentario,
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      height:
                                                                          1.4),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              }),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                  //TIPO DE PANTALLA - MOSTRAR COMPONENTES
                                  Builder(
                                    builder: (context) {
                                      if (widget.desdeVisitaperfilScreen) {
                                        return SizedBox.shrink();
                                      }
                                      if (widget.desdeVisitaperfilEmpresa) {
                                        return SizedBox.shrink();
                                      }
                                      if (widget.desdeVisitacarrito) {
                                        return SizedBox.shrink();
                                      }
                                      final String? userId =
                                          widget.producto['userid'];

                                      if (_empresas.isEmpty) {
                                        return Text('');
                                      }

                                      final empresa = userId != null
                                          ? _empresas.firstWhereOrNull(
                                              (e) => e['userid'] == userId)
                                          : null;

                                      final String? nombreEmpresa =
                                          empresa != null
                                              ? empresa['nombre']
                                              : widget.producto['nombre'];

                                      final String? fotoEmpresa = empresa !=
                                              null
                                          ? empresa['perfilEmpresa']
                                          : widget.producto['perfilEmpresa'];

                                      if (nombreEmpresa == null &&
                                          (fotoEmpresa == null ||
                                              fotoEmpresa.isEmpty)) {
                                        return Text('');
                                      }

                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Divider(
                                                  thickness: 1.5,
                                                  color: const Color.fromARGB(
                                                      255, 225, 225, 225),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 0,
                                                      vertical: 5),
                                                  child: Text(
                                                    'Acerca de la empresa',
                                                    style: theme
                                                        .textTheme.titleMedium
                                                        ?.copyWith(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: theme.textTheme
                                                          .bodyLarge?.color,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  margin: EdgeInsets.symmetric(
                                                      vertical: 10),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 55,
                                                        height: 55,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                              color: const Color(
                                                                  0xFFFFAF00),
                                                              width: 2),
                                                        ),
                                                        child: Stack(
                                                          alignment:
                                                              Alignment.center,
                                                          children: [
                                                            CircleAvatar(
                                                              radius: 25,
                                                              backgroundColor:
                                                                  const Color
                                                                      .fromARGB(
                                                                      0,
                                                                      238,
                                                                      238,
                                                                      238),
                                                              backgroundImage: (fotoEmpresa !=
                                                                          null &&
                                                                      fotoEmpresa
                                                                          .isNotEmpty)
                                                                  ? NetworkImage(
                                                                      fotoEmpresa)
                                                                  : AssetImage(
                                                                          'assets/images/empresa.png')
                                                                      as ImageProvider,
                                                              child: null,
                                                            ),
                                                            if (fotoEmpresa !=
                                                                    null &&
                                                                fotoEmpresa
                                                                    .isNotEmpty)
                                                              Positioned.fill(
                                                                child:
                                                                    FutureBuilder(
                                                                  future: precacheImage(
                                                                      NetworkImage(
                                                                          fotoEmpresa),
                                                                      context),
                                                                  builder: (context,
                                                                      snapshot) {
                                                                    if (snapshot
                                                                            .connectionState ==
                                                                        ConnectionState
                                                                            .done) {
                                                                      return SizedBox
                                                                          .shrink();
                                                                    } else {
                                                                      return Container(
                                                                        color: Colors
                                                                            .white
                                                                            .withOpacity(0.2),
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              CircularProgressIndicator(
                                                                            color:
                                                                                Color(0xFFFFC800),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              nombreEmpresa ??
                                                                  'Empresa sin nombre',
                                                              style: theme
                                                                  .textTheme
                                                                  .titleMedium
                                                                  ?.copyWith(
                                                                fontSize: 15,
                                                                color: theme
                                                                    .textTheme
                                                                    .bodyLarge
                                                                    ?.color,
                                                              ),
                                                            ),
                                                            Text(
                                                              'Ver perfil de empresa',
                                                              style: theme
                                                                  .textTheme
                                                                  .titleMedium
                                                                  ?.copyWith(
                                                                fontSize: 13,
                                                                color: theme
                                                                    .textTheme
                                                                    .bodyLarge
                                                                    ?.color,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (empresa != null)
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            final currentUserId =
                                                                FirebaseAuth
                                                                    .instance
                                                                    .currentUser
                                                                    ?.uid;
                                                            if (widget.producto[
                                                                    'userid'] ==
                                                                currentUserId) {
                                                              navegarConSlideDerecha(
                                                                context,
                                                                EmpresaProfileScreen(),
                                                              );
                                                            } else {
                                                              navegarConSlideDerecha(
                                                                  context,
                                                                  VisitaperfilScreem(
                                                                      empresa:
                                                                          empresa));
                                                            }
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                isDark
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black,
                                                            foregroundColor:
                                                                isDark
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white,
                                                            elevation: 0,
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        15,
                                                                    vertical:
                                                                        8),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                isCurrentUser
                                                                    ? 'Tú'
                                                                    : 'Visitar',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontFamily:
                                                                      'Afacad',
                                                                ),
                                                              ),
                                                              Icon(
                                                                Iconsax
                                                                    .arrow_right_3,
                                                                size: 20,
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                )
                                              ]);
                                        },
                                      );
                                    },
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ))),
            ])));
  }

  Widget buildCamposAdicionales() {
    final theme = Theme.of(context);
    String categoria = widget.producto['categoria'] ?? '';
    List<String> tallas = [];

    if (widget.producto['tipoPrenda'] == 'Parte inferior' &&
        widget.producto['tallaPantalon'] != null &&
        widget.producto['tallaPantalon'] is List) {
      tallas = List<String>.from(widget.producto['tallaPantalon']);
    } else if (widget.producto['talla'] != null &&
        widget.producto['talla'] is List) {
      tallas = List<String>.from(widget.producto['talla']);
    }

    if (categoria == 'Ropa' || categoria == 'Calzado') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 1, vertical: 10),
            child: Text(
              'Selecciona una talla:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 15,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tallas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final theme = Theme.of(context);
                  final isDark = theme.brightness == Brightness.dark;
                  final colorScheme = theme.colorScheme;

                  final talla = tallas[index];
                  final estaSeleccionada = _tallasSeleccionadas.contains(talla);

                  String subTexto = '';
                  if (widget.producto['tipoPrenda'] == 'Parte inferior') {
                    subTexto = convertirTallaPantalonACintura(talla);
                  } else if (categoria == 'Ropa') {
                    subTexto = convertirTallaRopaANumero(talla);
                  } else if (categoria == 'Calzado') {
                    subTexto = '${convertirTallaCalzadoACm(talla)} cm';
                  }

                  final backgroundColor = estaSeleccionada
                      ? (isDark ? Colors.amber : Colors.black)
                      : colorScheme.surface;

                  final textColor = estaSeleccionada
                      ? (isDark ? Colors.black : Colors.white)
                      : colorScheme.onSurface;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (estaSeleccionada) {
                          _tallasSeleccionadas.remove(talla);
                        } else {
                          _tallasSeleccionadas
                            ..clear()
                            ..add(talla);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: estaSeleccionada
                              ? backgroundColor
                              : Colors.grey.withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            talla,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subTexto.isNotEmpty)
                            Text(
                              subTexto,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withOpacity(0.9),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    if (categoria == 'Tecnologias') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.producto['marca'] != null)
            Row(
              children: [
                Text(
                  'Marca:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '${widget.producto['marca']}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
        ],
      );
    }

    if (categoria == 'Juguetes') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.producto['marca'] != null)
            Row(
              children: [
                Text(
                  'Proveedor:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '${widget.producto['marca']}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
        ],
      );
    }

    return SizedBox.shrink();
  }
}
