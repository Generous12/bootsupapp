import 'package:bootsup/Vista/EmpresaVista/VisitasPerfilYPublicaciones/todosProducos/filtro.dart';
import 'package:bootsup/Vistas/detalleproducto/detalleProducto.dart';
import 'package:bootsup/widgets/AnimacionCambioScreen.dart';
import 'package:bootsup/widgets/BotonesSeleccionables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:redacted/redacted.dart';

class ComprasPage extends StatefulWidget {
  const ComprasPage({super.key});

  @override
  _ComprasPageState createState() => _ComprasPageState();
}

class _ComprasPageState extends State<ComprasPage> {
  String? selectedCategoria;
  List<DocumentSnapshot> _allProductos = [];
  TextEditingController _searchController = TextEditingController();

  List<DocumentSnapshot> _productos = [];
  List _productosAleatorios = [];
  bool _isRedacted = true;
  int _productosPorPagina = 8;
  int _paginaActual = 1;
  bool _isCargandoMas = false;
  bool _todosCargados = false;
  final ScrollController _scrollController = ScrollController();
  String? _categoriaSeleccionada;

  void _cargarProductos({String? criterio, String? categoria}) async {
    setState(() {
      _isRedacted = true;
      _paginaActual = 1;
      _todosCargados = false;
      _productosAleatorios.clear();
    });

    Query query = FirebaseFirestore.instance.collection('productos');

    // 🔽 Aplicar filtro de categoría si no es 'General'
    if (categoria != null && categoria != 'General') {
      query = query.where('categoria', isEqualTo: categoria);
    }

    // 🔽 Aplicar orden según el criterio
    if (criterio == 'recientes') {
      query = query.orderBy('fecha', descending: true);
    } else if (criterio == 'precioMenor') {
      query = query.orderBy('precio');
    } else if (criterio == 'precioMayor') {
      query = query.orderBy('precio', descending: true);
    }

    final snapshot = await query.get();

    if (criterio == 'rating') {
      final productosConRating = await Future.wait(
        snapshot.docs.map((doc) async {
          final comentariosSnap =
              await doc.reference.collection('comentarios').get();
          final comentarios = comentariosSnap.docs;

          double promedio = 0;
          if (comentarios.isNotEmpty) {
            final total = comentarios
                .map((c) => (c['rating'] ?? 0).toDouble())
                .reduce((a, b) => a + b);
            promedio = total / comentarios.length;
          }

          return {
            'doc': doc,
            'promedioRating': promedio,
          };
        }),
      );

      productosConRating.sort((a, b) => (b['promedioRating'] as double)
          .compareTo(a['promedioRating'] as double));

      _productos =
          productosConRating.map((e) => e['doc'] as DocumentSnapshot).toList();
    } else if (criterio == 'comentarios') {
      final productosConComentarios = await Future.wait(
        snapshot.docs.map((doc) async {
          final comentarios =
              await doc.reference.collection('comentarios').get();
          return {
            'doc': doc,
            'comentarios': comentarios.size,
          };
        }),
      );

      productosConComentarios.sort((a, b) =>
          (b['comentarios'] as int).compareTo(a['comentarios'] as int));

      _productos = productosConComentarios
          .map((e) => e['doc'] as DocumentSnapshot)
          .toList();
    } else {
      _productos = snapshot.docs;
    }

    // Aleatorizar si no hay criterio
    if (criterio == null || criterio == 'aleatorio') {
      _productos.shuffle();
    }

    setState(() {
      _productosAleatorios = _productos.take(_productosPorPagina).toList();
      _isRedacted = false;
    });
  }

  Future<void> _fetchProductos({String? categoria}) async {
    try {
      final productosQuery = categoria != null && categoria.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('productos')
              .where('categoria', isEqualTo: categoria)
          : FirebaseFirestore.instance.collection('productos');

      final productosSnapshot = await productosQuery.get();

      if (mounted) {
        final List<DocumentSnapshot> shuffled =
            List<DocumentSnapshot>.from(productosSnapshot.docs)..shuffle();

        setState(() {
          _allProductos = shuffled;
          _productos = List.from(_allProductos);
        });
      }
    } catch (e) {
      debugPrint("Error al cargar los productos: $e");
    }
  }

  Future<void> _fetchAndRedactProductos({String? categoria}) async {
    if (!mounted) return;
    setState(() {
      _isRedacted = true;
      _paginaActual = 1;
      _todosCargados = false;
      _productosAleatorios.clear();
    });

    if (categoria == null || categoria == 'General') {
      await _fetchProductos();
    } else {
      await _fetchProductos(categoria: categoria);
    }

    _productosAleatorios = List.from(_productos);
    _productosAleatorios.shuffle();

    if (!mounted) return;
    setState(() {
      _isRedacted = false;
      _productosAleatorios = _productos.take(_productosPorPagina).toList();
    });
  }

  void _cargarMasProductos() {
    if (_isCargandoMas || _todosCargados) return;

    setState(() {
      _isCargandoMas = true;
    });

    final int siguienteIndex = _paginaActual * _productosPorPagina;
    final siguienteProductos =
        _productos.skip(siguienteIndex).take(_productosPorPagina).toList();

    if (siguienteProductos.isEmpty) {
      if (!mounted) return;
      setState(() {
        _todosCargados = true;
        _isCargandoMas = false;
      });
      return;
    }

    Future.delayed(Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _productosAleatorios.addAll(siguienteProductos);
        _paginaActual++;
        _isCargandoMas = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();

    _isRedacted = true;
    selectedCategoria = 'General';
    _fetchAndRedactProductos(categoria: selectedCategoria);

    _searchController.addListener(() {
      String query = _searchController.text.toLowerCase();
      setState(() {
        if (query.isEmpty) {
          _productos = List.from(_allProductos);
        } else {
          _productos = _allProductos.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final nombre =
                data['nombreProducto']?.toString().toLowerCase() ?? '';
            return nombre.contains(query);
          }).toList();
        }
        _paginaActual = 1;
        _todosCargados = false;
        _productosAleatorios = _productos.take(_productosPorPagina).toList();
      });
    });
  }

  Future<void> cargarContenido() async {
    setState(() {
      _isCargandoMas = true;
    });

    selectedCategoria = 'General';
    _fetchAndRedactProductos(categoria: selectedCategoria);

    if (mounted) {
      setState(() {
        _isCargandoMas = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: RefreshIndicator(
            color: const Color(0xFFFFAF00),
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            onRefresh: () async {
              await cargarContenido();
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
                toolbarHeight: 70,
                title: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: theme.iconTheme.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            fontFamily: 'Afacad',
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Buscar productos...',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontFamily: 'Afacad',
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _searchController.clear()),
                          child: Icon(Iconsax.close_circle,
                              color: theme.iconTheme.color),
                        ),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(18)),
                            ),
                            builder: (context) => FiltrosAdicionalesSheet(
                              onFiltroSeleccionado: (criterio) {
                                Navigator.pop(context);
                                _cargarProductos(
                                  criterio: criterio,
                                  categoria: _categoriaSeleccionada,
                                );
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(40),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: CategoriaSelector(
                      onCategoriaSelected: (value) {
                        setState(() {
                          _productosAleatorios.clear();
                          _todosCargados = false;
                          _isCargandoMas = false;
                          _categoriaSeleccionada = value;
                          FocusScope.of(context).unfocus();
                        });
                        _fetchAndRedactProductos(
                            categoria: _categoriaSeleccionada);
                      },
                    ),
                  ),
                ),
              ),
              if (_isRedacted)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: const Color(0xFFFFAF00),
                        size: 40,
                      ),
                    ),
                  ),
                )
              else if (_productosAleatorios.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 250),
                      child: Text(
                        'No hay productos disponibles.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(10),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= _productosAleatorios.length) {
                          return const SizedBox();
                        }

                        if (index == _productosAleatorios.length - 1 &&
                            !_todosCargados &&
                            !_isCargandoMas) {
                          WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _cargarMasProductos());
                        }

                        var productoDoc = _productosAleatorios[index];

                        var producto = _productosAleatorios[index].data()
                            as Map<String, dynamic>;
                        producto['id'] = productoDoc.id;

                        var imagenes =
                            List<String>.from(producto['imagenes'] ?? []);
                        final precioRaw = producto['precio'];
                        final descuentoRaw = producto['descuento'];

                        double precioOriginal = 0.0;
                        if (precioRaw is String) {
                          precioOriginal = double.tryParse(precioRaw) ?? 0.0;
                        } else if (precioRaw is int) {
                          precioOriginal = precioRaw.toDouble();
                        } else if (precioRaw is double) {
                          precioOriginal = precioRaw;
                        }

                        double descuento = 0.0;
                        if (descuentoRaw is String) {
                          descuento = double.tryParse(descuentoRaw) ?? 0.0;
                        } else if (descuentoRaw is int) {
                          descuento = descuentoRaw.toDouble();
                        } else if (descuentoRaw is double) {
                          descuento = descuentoRaw;
                        }

                        final bool hayDescuento = descuento > 0;
                        return GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            navegarConSlideIzquierda(
                              context,
                              DetalleProductoPage(
                                producto: producto,
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color.fromARGB(255, 232, 232, 232)
                                          .withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(
                                  tag: 'producto_${producto['id']}_$index',
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: (imagenes.isNotEmpty &&
                                              imagenes[0].isNotEmpty
                                          ? Image.network(
                                              imagenes[0],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.asset(
                                                  'assets/images/empresa.png',
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                ).redacted(
                                                    context: context,
                                                    redact: _isRedacted);
                                              },
                                            ).redacted(
                                              context: context,
                                              redact: _isRedacted)
                                          : Image.asset(
                                              'assets/images/empresa.png',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            ).redacted(
                                              context: context,
                                              redact: _isRedacted)),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Text(
                                            (() {
                                              final desc =
                                                  producto['nombreProducto'] ??
                                                      '';
                                              final trimmed = desc.length > 18
                                                  ? desc.substring(0, 18) +
                                                      '...'
                                                  : desc;
                                              return trimmed;
                                            })(),
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontSize: 15,
                                              color: theme
                                                  .textTheme.bodyLarge?.color,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ).redacted(
                                            context: context,
                                            redact: _isRedacted,
                                          ),
                                        ),
                                        if (!_isRedacted)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            child: Text(
                                              (() {
                                                final desc =
                                                    producto['descripcion'] ??
                                                        '';
                                                final trimmed = desc.length > 40
                                                    ? desc.substring(0, 40) +
                                                        '...'
                                                    : desc;
                                                return trimmed;
                                              })(),
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontSize: 12,
                                                color: theme
                                                    .textTheme.bodyLarge?.color,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        Spacer(),
                                        if (!_isRedacted)
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
                                                      style: theme
                                                          .textTheme.titleMedium
                                                          ?.copyWith(
                                                        fontSize: 13,
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                        color: theme.textTheme
                                                            .bodyLarge?.color,
                                                      ),
                                                    ).redacted(
                                                      context: context,
                                                      redact: _isRedacted,
                                                    ),
                                                  Text(
                                                    'S/ ${(hayDescuento ? (precioOriginal * (1 - descuento / 100)) : precioOriginal).toStringAsFixed(2)}',
                                                    style: theme
                                                        .textTheme.titleMedium
                                                        ?.copyWith(
                                                      fontSize: 19,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: theme.textTheme
                                                          .bodyLarge?.color,
                                                    ),
                                                  ).redacted(
                                                    context: context,
                                                    redact: _isRedacted,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(width: 30),
                                              if (hayDescuento)
                                                Text(
                                                  '${descuento.toStringAsFixed(0)}% OFF',
                                                  style: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        theme.colorScheme.error,
                                                  ),
                                                ).redacted(
                                                  context: context,
                                                  redact: _isRedacted,
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
                      childCount: _productosAleatorios.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: _isRedacted ? 0.75 : 0.57,
                    ),
                  ),
                ),
              if (_isCargandoMas)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: const Color(0xFFFFAF00),
                        size: 40,
                      ),
                    ),
                  ),
                ),
            ])));
  }
}
