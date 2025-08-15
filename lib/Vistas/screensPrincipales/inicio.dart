import 'package:bootsup/Modulos/ModuloPublicaciones/Moduloinicio.dart';
import 'package:bootsup/Vista/EmpresaVista/VisitasPerfilYPublicaciones/VisitaPerfil.dart';
import 'package:bootsup/Vista/EmpresaVista/VisitasPerfilYPublicaciones/todoLosProductos.dart';
import 'package:bootsup/Vistas/detalleproducto/ComentariosScreen/Comentarios.dart';
import 'package:bootsup/Vistas/detalleproducto/detalleProducto.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:timeago/timeago.dart' as timeago;

class Inicio extends StatefulWidget {
  @override
  _InicioState createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  List<Map<String, dynamic>> _publicaciones = [];

  List<String> _idsMostrados = [];
  //PAGINACION
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isInitialLoading = true;
  final ScrollController _scrollController = ScrollController();

  final _firestoreService = FirestoreService();
  Set<String> _publicacionesConLike = {};
  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    _cargarMasPublicaciones(userId);

    _checkSignInStatus();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoadingMore &&
          _hasMore) {
        _cargarMasPublicaciones(userId);
      }
    });
  }

  Future<void> _checkSignInStatus() async {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _cargarMasPublicaciones(String userId) async {
    if (!mounted || _isLoadingMore || !_hasMore) return;
    if (!mounted) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nuevasPublicaciones =
          await FirestoreService.fetchPublicacionesConEmpresa(
        idsMostrados: _idsMostrados,
        limit: 6,
        userId: userId,
      );

      final productos = await FirestoreService.fetchProductos();
      if (nuevasPublicaciones.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
        return;
      } // 🔹 Opcional: Actualiza la lista de publicaciones con like
      for (var publicacion in nuevasPublicaciones) {
        final publicacionId = publicacion['docRef'].id;
        final dioLike = publicacion['dioLike'] == true;
        if (dioLike && !_publicacionesConLike.contains(publicacionId)) {
          _publicacionesConLike.add(publicacionId);
        }
      }
      if (!mounted) return;
      setState(() {
        _publicaciones.addAll(nuevasPublicaciones);
        _productos = List.from(productos)..shuffle();
        _hasMore = nuevasPublicaciones.length >= 6;
        _isLoadingMore = false;
        _isInitialLoading = false;
      });
    } catch (e) {
      print('Error al cargar más publicaciones: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> cargarContenido(String userId) async {
    if (!mounted) return;

    setState(() {
      _isInitialLoading = true;
      _publicaciones.clear();
      _publicacionesConLike.clear();
      _idsMostrados.clear();
      _hasMore = true;
      _isLoadingMore = false;
    });

    await _cargarMasPublicaciones(userId);
    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return RefreshIndicator(
        color: const Color(0xFFFFAF00),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        onRefresh: () async {
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            await cargarContenido(userId);
          }
        },
        child: CustomScrollView(controller: _scrollController, slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            snap: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            automaticallyImplyLeading: false,
            toolbarHeight: 40,
            title: const Text(
              'BoosTup',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFAF00),
              ),
            ),
          ),
          if (_isInitialLoading)
            SliverToBoxAdapter(
              child: const RedactedPublicacion(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _publicaciones.length) {
                    return _isLoadingMore
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: LoadingAnimationWidget.staggeredDotsWave(
                                color: const Color(0xFFFFAF00),
                                size: 40,
                              ),
                            ),
                          )
                        : const SizedBox.shrink();
                  }

                  final publicacion = _publicaciones[index];
                  final empresaData = publicacion['empresa'];

                  final nombreEmpresa =
                      publicacion['publicacion'] ?? 'Empresa desconocida';
                  final perfilEmpresa = publicacion['perfilEmpresa'] ?? '';
                  final publicacionId = publicacion['docRef'].id;
                  final _leDioLike =
                      _publicacionesConLike.contains(publicacionId);
                  final userId = FirebaseAuth.instance.currentUser?.uid;

                  final publicacionCard = Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                      elevation: 0,
                      color: theme.scaffoldBackgroundColor,
                      margin:
                          EdgeInsets.symmetric(horizontal: 0.0, vertical: 5.0),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          theme.scaffoldBackgroundColor,
                                      child: ClipOval(
                                        child: (perfilEmpresa.isNotEmpty)
                                            ? Image.network(
                                                perfilEmpresa,
                                                fit: BoxFit.cover,
                                                width: 40,
                                                height: 40,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return Center(
                                                    child: SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                        strokeWidth: 2.0,
                                                        color:
                                                            Color(0xFFFFC800),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Image.asset(
                                                    'assets/images/empresa.png',
                                                    fit: BoxFit.cover,
                                                    width: 40,
                                                    height: 40,
                                                  );
                                                },
                                              )
                                            : Image.asset(
                                                'assets/images/empresa.png',
                                                fit: BoxFit.cover,
                                                width: 40,
                                                height: 40,
                                              ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          navegarConSlideDerecha(
                                            context,
                                            VisitaperfilScreem(
                                                empresa: empresaData),
                                          );
                                        },
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nombreEmpresa,
                                              style: TextStyle(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Text(
                                                  publicacion['fecha'] != null
                                                      ? timeago.format(
                                                          publicacion['fecha'],
                                                          locale: 'es')
                                                      : 'Sin fecha',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        const Color(0xFF757575),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Icon(
                                                  Iconsax.global,
                                                  size: 20,
                                                  color: Color(0xFF757575),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Text(
                                  publicacion['descripcion'] ?? '',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 14,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                SizedBox(height: 2),
                                if (publicacion['imagenes'] != null &&
                                    publicacion['imagenes'] is List &&
                                    (publicacion['imagenes'] as List)
                                        .isNotEmpty)
                                  Builder(
                                    builder: (context) {
                                      final List imagenes =
                                          publicacion['imagenes'];
                                      final PageController _pageController =
                                          PageController();
                                      final ratio = publicacion['imageRatio'] ??
                                          {'width': 1.0, 'height': 1.0};
                                      final aspectRatio =
                                          (ratio['width'] ?? 1.0) /
                                              (ratio['height'] ?? 1.0);

                                      return Column(
                                        children: [
                                          AspectRatio(
                                            aspectRatio: aspectRatio,
                                            child: Stack(
                                              children: [
                                                PageView.builder(
                                                  controller: _pageController,
                                                  itemCount: imagenes.length,
                                                  itemBuilder:
                                                      (context, imgIndex) {
                                                    final String imageUrl =
                                                        imagenes[imgIndex];

                                                    return ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              0),
                                                      child: imageUrl.isNotEmpty
                                                          ? Image.network(
                                                              imageUrl,
                                                              fit: BoxFit.cover,
                                                              loadingBuilder:
                                                                  (context,
                                                                      child,
                                                                      loadingProgress) {
                                                                if (loadingProgress ==
                                                                    null)
                                                                  return child;
                                                                return const Center(
                                                                  child:
                                                                      CircularProgressIndicator(
                                                                    color: Color(
                                                                        0xFFFFAF00),
                                                                    strokeWidth:
                                                                        2.5,
                                                                  ),
                                                                );
                                                              },
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Image
                                                                    .asset(
                                                                  'assets/images/empresa.png',
                                                                  fit: BoxFit
                                                                      .cover,
                                                                );
                                                              },
                                                            )
                                                          : Image.asset(
                                                              'assets/images/empresa.png',
                                                              fit: BoxFit.cover,
                                                            ),
                                                    );
                                                  },
                                                ),
                                                Positioned(
                                                  bottom: 12,
                                                  left: 0,
                                                  right: 0,
                                                  child: Center(
                                                    child: SmoothPageIndicator(
                                                      controller:
                                                          _pageController,
                                                      count: imagenes.length,
                                                      effect: JumpingDotEffect(
                                                        activeDotColor:
                                                            Color(0xFFFFAF00),
                                                        dotColor:
                                                            Color.fromARGB(255,
                                                                126, 126, 126),
                                                        dotHeight: 8,
                                                        dotWidth: 8,
                                                        spacing: 6,
                                                        jumpScale: 1.5,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Material(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 0),
                                              decoration: BoxDecoration(
                                                color: theme
                                                    .scaffoldBackgroundColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  // Botón de Like
                                                  GestureDetector(
                                                    onTap: () async {
                                                      if (userId == null ||
                                                          publicacionId == null)
                                                        return;

                                                      final dioLike =
                                                          await _firestoreService
                                                              .haDadoMeGusta(
                                                                  publicacionId,
                                                                  userId);

                                                      if (dioLike) {
                                                        await _firestoreService
                                                            .quitarMeGusta(
                                                                publicacionId,
                                                                userId);
                                                        _publicacionesConLike
                                                            .remove(
                                                                publicacionId);
                                                        _publicaciones[index][
                                                            'cantidadMeGustas']--;
                                                        _publicaciones[index]
                                                            ['dioLike'] = false;
                                                      } else {
                                                        await _firestoreService
                                                            .darMeGusta(
                                                                publicacionId,
                                                                userId);
                                                        _publicacionesConLike
                                                            .add(publicacionId);
                                                        _publicaciones[index][
                                                            'cantidadMeGustas']++;
                                                        _publicaciones[index]
                                                            ['dioLike'] = true;
                                                      }

                                                      setState(() {});
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Iconsax.flash,
                                                          size: 28,
                                                          color: _leDioLike
                                                              ? colorScheme
                                                                  .primary
                                                              : colorScheme
                                                                  .onBackground,
                                                        ),
                                                        const SizedBox(
                                                            width: 6),
                                                        Text(
                                                          _publicaciones[index][
                                                                  'cantidadMeGustas']
                                                              .toString(),
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            color: colorScheme
                                                                .onBackground,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  const SizedBox(width: 32),
                                                  GestureDetector(
                                                    onTap: () {
                                                      showBarModalBottomSheet(
                                                        context: context,
                                                        expand: true,
                                                        builder: (context) =>
                                                            ComentariosScreen(
                                                          publicacionId:
                                                              publicacionId,
                                                          userId: userId!,
                                                        ),
                                                      );
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          LucideIcons
                                                              .messageCircle,
                                                          size: 28,
                                                          color: colorScheme
                                                              .onBackground,
                                                        ),
                                                        const SizedBox(
                                                            width: 6),
                                                        StreamBuilder<
                                                            QuerySnapshot>(
                                                          stream: FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'publicaciones')
                                                              .doc(
                                                                  publicacionId)
                                                              .collection(
                                                                  'comentarios')
                                                              .snapshots(),
                                                          builder: (context,
                                                              snapshot) {
                                                            if (!snapshot
                                                                .hasData) {
                                                              return Text(
                                                                '...',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    color: colorScheme
                                                                        .onBackground),
                                                              );
                                                            }

                                                            final cantidadComentarios =
                                                                snapshot
                                                                    .data!
                                                                    .docs
                                                                    .length;

                                                            return Text(
                                                              cantidadComentarios
                                                                  .toString(),
                                                              style: TextStyle(
                                                                  fontSize: 16,
                                                                  color: colorScheme
                                                                      .onBackground),
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  const SizedBox(width: 32),

                                                  // Botón de Productos
                                                  GestureDetector(
                                                    onTap: () {
                                                      navegarConSlideDerecha(
                                                        context,
                                                        TodosLosProductosPage(
                                                          empresaUserId:
                                                              publicacion[
                                                                  'empresaId'],
                                                          productosPasados:
                                                              _productos,
                                                          desdePublicaciones:
                                                              true,
                                                        ),
                                                      );
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Iconsax.box,
                                                          size: 28,
                                                          color: colorScheme
                                                              .onBackground,
                                                        ),
                                                        const SizedBox(
                                                            width: 6),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ));
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        publicacionCard,
                        _filaDeProductos(context),
                      ],
                    );
                  }
                  return publicacionCard;
                },
                childCount: _publicaciones.length + 1,
              ),
            )
        ]));
  }

  List<DocumentSnapshot> _productos = [];

  Widget _filaDeProductos(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 315,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _productos.length > 6 ? 6 : _productos.length,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemBuilder: (context, index) {
          var productoDoc = _productos[index];
          final producto = _productos[index].data() as Map<String, dynamic>;
          producto['id'] = productoDoc.id;
          final imagenes = List<String>.from(producto['imagenes'] ?? []);
          final double precioOriginal =
              double.tryParse(producto['precio'].toString()) ?? 0.0;
          final double descuento =
              double.tryParse(producto['descuento']?.toString() ?? '0') ?? 0.0;
          final bool hayDescuento = descuento > 0;
          final double precioConDescuento =
              precioOriginal * (1 - descuento / 100);
          return GestureDetector(
            onTap: () {
              navegarConSlideDerecha(
                context,
                DetalleProductoPage(
                  producto: producto,
                ),
              );
            },
            child: Container(
              width: 165,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: (imagenes.isNotEmpty &&
                                imagenes[0].toString().isNotEmpty
                            ? Image.network(
                                imagenes[0],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/empresa.png',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  );
                                },
                              )
                            : Image.asset(
                                'assets/images/empresa.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ))),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto['nombreProducto'] ?? '',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 15,
                              color: theme.textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 10),
                          Text(
                            producto['descripcion'] ?? '',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 12,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hayDescuento)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'S/ ${precioOriginal.toStringAsFixed(2)}',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 14,
                                        decoration: TextDecoration.lineThrough,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    Text(
                                      'S/ ${precioConDescuento.toStringAsFixed(2)}',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              if (!hayDescuento)
                                Text(
                                  'S/ ${precioOriginal.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              if (hayDescuento)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8.0, top: 2.0),
                                  child: Text(
                                    '${descuento.toStringAsFixed(0)}% OFF',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RedactedPublicacion extends StatelessWidget {
  const RedactedPublicacion({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      elevation: 0,
      color: theme.scaffoldBackgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: baseColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 100,
                        color: baseColor,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
                        width: 80,
                        color: baseColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 14,
              width: double.infinity,
              color: baseColor,
            ),
            const SizedBox(height: 6),
            Container(
              height: 14,
              width: double.infinity,
              color: baseColor,
            ),
            const SizedBox(height: 6),
            Container(
              height: 14,
              width: 200,
              color: baseColor,
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.3,
              child: Container(
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (_) {
                return Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: baseColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 20,
                      height: 14,
                      color: baseColor,
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return Container(
                    width: 140,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
